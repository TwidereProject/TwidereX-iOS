//
//  HomeTimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-1.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterAPI

final class HomeTimelineViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = HomeTimelineViewModel(context: context)
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(TimelinePostTableViewCell.self, forCellReuseIdentifier: String(describing: TimelinePostTableViewCell.self))
        tableView.register(TimelineMiddleLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false
        return tableView
    }()
    
    let refreshControl = UIRefreshControl()
}

extension HomeTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(HomeTimelineViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        
        #if DEBUG
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(title: "TopGap", style: .plain, target: self, action: #selector(HomeTimelineViewController.topGapBarButtonItemPressed(_:)))
        ]
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Drop", style: .plain, target: self, action: #selector(HomeTimelineViewController.dropBarButtonItemPressed(_:))),
            UIBarButtonItem(title: "Last", style: .plain, target: self, action: #selector(HomeTimelineViewController.lastBarButtonItemPressed(_:)))
        ]
        #endif
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.backgroundColor = .systemBackground
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        
        viewModel.contentOffsetAdjustableTimelineViewControllerDelegate = self
        viewModel.tableView = tableView
        viewModel.timelinePostTableViewCellDelegate = self
        viewModel.timelineMiddleLoaderTableViewCellDelegate = self
        viewModel.setupDiffableDataSource(for: tableView)
        do {
            try viewModel.fetchedResultsController.performFetch()
        } catch {
            assertionFailure(error.localizedDescription)
        }
        tableView.delegate = self
        tableView.dataSource = viewModel.diffableDataSource
        
        // bind view model
        context.authenticationService.twitterAuthentications
            .map { $0.first }
            .assign(to: \.value, on: viewModel.currentTwitterAuthentication)
            .store(in: &disposeBag)
        
        // bind refresh control
        viewModel.isFetchingLatestTimeline
            .sink { [weak self] isFetching in
                guard let self = self else { return }
                if !isFetching {
                    self.refreshControl.endRefreshing()
                }
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.once {
            if (self.viewModel.fetchedResultsController.fetchedObjects ?? []).count == 0 {
                self.viewModel.loadLatestStateMachine.enter(HomeTimelineViewModel.LoadLatestState.Loading.self)
            }
        }
    }
 
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { _ in
            // do nothing
        } completion: { _ in
            // fix AutoLayout cell height not update after rotate issue
            self.viewModel.cellFrameCache.removeAllObjects()
            self.tableView.reloadData()
            
        }
    }

}

extension HomeTimelineViewController {
    
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        guard viewModel.loadLatestStateMachine.enter(HomeTimelineViewModel.LoadLatestState.Loading.self) else {
            sender.endRefreshing()
            return
        }
    }
    
    #if DEBUG
    @objc private func topGapBarButtonItemPressed(_ sender: UIBarButtonItem) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshot = diffableDataSource.snapshot()
        let item = snapshot.itemIdentifiers.first(where: { item in
            switch item {
            case .homeTimelineMiddleLoader: return true
            default:                        return false
            }
        })
        if let targetItem = item, let index = snapshot.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
        }
    }
    
    @objc private func dropBarButtonItemPressed(_ sender: UIBarButtonItem) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshot = diffableDataSource.snapshot()
        
        let droppingObjectIDs = snapshot.itemIdentifiers.prefix(50).compactMap { item -> NSManagedObjectID? in
            switch item {
            case .homeTimelineIndex(let objectID, _):   return objectID
            default:                                    return nil
            }
        }
        context.apiService.backgroundManagedObjectContext.performChanges {
            for objectID in droppingObjectIDs {
                guard let object = try? self.context.apiService.backgroundManagedObjectContext.existingObject(with: objectID) as? TimelineIndex else { continue }
                self.context.apiService.backgroundManagedObjectContext.delete(object.tweet!)
                self.context.apiService.backgroundManagedObjectContext.delete(object)
            }
        }
        .sink { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                assertionFailure(error.localizedDescription)
            }
        }
        .store(in: &disposeBag)
    }
    
    @objc private func lastBarButtonItemPressed(_ sender: UIBarButtonItem) {
        if let last = viewModel.fetchedResultsController.fetchedObjects?.last {
            let objectID = last.objectID
            context.apiService.backgroundManagedObjectContext.performChanges {
                let object = self.context.apiService.backgroundManagedObjectContext.object(with: objectID) as! TimelineIndex
                object.tweet!.update(hasMore: true)
            }
            .sink { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    assertionFailure(error.localizedDescription)
                }
            }
            .store(in: &disposeBag)
        }
        
    }
    #endif
}

// MARK: - UIScrollViewDelegate
extension HomeTimelineViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        let cells = tableView.visibleCells.compactMap { $0 as? TimelineBottomLoaderTableViewCell }
        guard let loaderTableViewCell = cells.first else { return }
        
        if let tabBar = tabBarController?.tabBar, let window = view.window {
            let loaderTableViewCellFrameInWindow = tableView.convert(loaderTableViewCell.frame, to: nil)
            let windowHeight = window.frame.height
            let loaderAppear = (loaderTableViewCellFrameInWindow.origin.y + 0.8 * loaderTableViewCell.frame.height) < (windowHeight - tabBar.frame.height)
            if loaderAppear {
                viewModel.loadoldestStateMachine.enter(HomeTimelineViewModel.LoadOldestState.Loading.self)
            }
        } else {
            viewModel.loadoldestStateMachine.enter(HomeTimelineViewModel.LoadOldestState.Loading.self)
        }
    }
}


// MARK: - UITableViewDelegate
extension HomeTimelineViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let diffableDataSource = viewModel.diffableDataSource else { return 100 }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return 100 }
        
        guard let frame = viewModel.cellFrameCache.object(forKey: NSNumber(value: item.hashValue))?.cgRectValue else {
            return 200
        }
        // os_log("%{public}s[%{public}ld], %{public}s: cache cell frame %s", ((#file as NSString).lastPathComponent), #line, #function, frame.debugDescription)

        return ceil(frame.height)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        os_log("%{public}s[%{public}ld], %{public}s: indexPath %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)
        
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .homeTimelineIndex(let objectID, _):
            let managedObjectContext = self.viewModel.fetchedResultsController.managedObjectContext
            managedObjectContext.performAndWait {
                guard let timelineIndex = managedObjectContext.object(with: objectID) as? TimelineIndex else { return }
                guard let tweet = timelineIndex.tweet?.retweet ?? timelineIndex.tweet else { return }
                
                let tweetPostViewModel = TweetConversationViewModel(context: self.context, tweetObjectID: tweet.objectID)
                self.coordinator.present(scene: .tweetPost(viewModel: tweetPostViewModel), from: self, transition: .show)
            }
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        let key = item.hashValue
        let frame = cell.frame
        viewModel.cellFrameCache.setObject(NSValue(cgRect: frame), forKey: NSNumber(value: key))
    }
    
}

// MARK: - ContentOffsetAdjustableTimelineViewControllerDelegate
extension HomeTimelineViewController: ContentOffsetAdjustableTimelineViewControllerDelegate {
    func navigationBar() -> UINavigationBar {
        return navigationController!.navigationBar
    }
}

// MARK: - TimelinePostTableViewCellDelegate
extension HomeTimelineViewController: TimelinePostTableViewCellDelegate {
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, retweetInfoLabelDidPressed label: UILabel) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .homeTimelineIndex(let objectID, _):
            let managedObjectContext = self.viewModel.fetchedResultsController.managedObjectContext
            managedObjectContext.performAndWait {
                guard let timelineIndex = managedObjectContext.object(with: objectID) as? TimelineIndex else { return }
                guard let tweet = timelineIndex.tweet else { return }
                let twitterUser = tweet.user
                let profileViewModel = ProfileViewModel(twitterUser: twitterUser)
                self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
            }
        default:
            return
        }
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, avatarImageViewDidPressed imageView: UIImageView) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .homeTimelineIndex(let objectID, _):
            let managedObjectContext = self.viewModel.fetchedResultsController.managedObjectContext
            managedObjectContext.performAndWait {
                guard let timelineIndex = managedObjectContext.object(with: objectID) as? TimelineIndex else { return }
                guard let tweet = timelineIndex.tweet?.retweet ?? timelineIndex.tweet else { return }
                let twitterUser = tweet.user
                let profileViewModel = ProfileViewModel(twitterUser: twitterUser)
                self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
            }
        default:
            return
        }
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, quoteAvatarImageViewDidPressed imageView: UIImageView) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .homeTimelineIndex(let objectID, _):
            let managedObjectContext = self.viewModel.fetchedResultsController.managedObjectContext
            managedObjectContext.performAndWait {
                guard let timelineIndex = managedObjectContext.object(with: objectID) as? TimelineIndex else { return }
                guard let tweet = timelineIndex.tweet?.retweet?.quote ?? timelineIndex.tweet?.quote else { return }
                let twitterUser = tweet.user
                let profileViewModel = ProfileViewModel(twitterUser: twitterUser)
                self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
            }
        default:
            return
        }
    }
}

// MARK: - TimelineMiddleLoaderTableViewCellDelegate
extension HomeTimelineViewController: TimelineMiddleLoaderTableViewCellDelegate {
    func timelineMiddleLoaderTableViewCell(_ cell: TimelineMiddleLoaderTableViewCell, loadMoreButtonDidPressed button: UIButton) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .homeTimelineMiddleLoader(let upper):
            guard let stateMachine = viewModel.loadMiddleSateMachineList.value[upper] else {
                assertionFailure()
                return
            }
            stateMachine.enter(HomeTimelineViewModel.LoadMiddleState.Loading.self)
        default:
            assertionFailure()
        }
    }
}
