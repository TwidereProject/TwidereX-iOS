//
//  HomeTimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-1.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterAPI
import Floaty
import AlamofireImage

final class HomeTimelineViewController: UIViewController, NeedsDependency, DrawerSidebarTransitionableViewController, MediaPreviewableViewController {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = HomeTimelineViewModel(context: context)
    
    private(set) var drawerSidebarTransitionController: DrawerSidebarTransitionController!
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    let avatarButton = UIButton.avatarButton
    lazy var avatarBarButtonItem = UIBarButtonItem(customView: avatarButton)
    
    lazy var tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(TimelinePostTableViewCell.self, forCellReuseIdentifier: String(describing: TimelinePostTableViewCell.self))
        tableView.register(TimelineMiddleLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
    let refreshControl = UIRefreshControl()
    
    private lazy var floatyButton: Floaty = {
        let button = Floaty()
        button.plusColor = .white
        button.buttonColor = Asset.Colors.hightLight.color
        button.buttonImage = Asset.Editing.featherPen.image
        button.handleFirstItemDirectly = true
        
        let composeItem: FloatyItem = {
            let item = FloatyItem()
            item.title = "Compose"
            item.handler = self.composeFloatyButtonPressed
            return item
        }()
        button.addItem(item: composeItem)
        
        return button
    }()

}

extension HomeTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = avatarBarButtonItem
        avatarButton.addTarget(self, action: #selector(HomeTimelineViewController.avatarButtonPressed(_:)), for: .touchUpInside)
        
        drawerSidebarTransitionController = DrawerSidebarTransitionController(drawerSidebarTransitionableViewController: self)
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(HomeTimelineViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        
        #if DEBUG
        if #available(iOS 14.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "More",
                image: UIImage(systemName: "ellipsis.circle"),
                primaryAction: nil,
                menu: UIMenu(
                    title: "Debug Tools",
                    image: nil,
                    identifier: nil,
                    options: .displayInline,
                    children: [
                        UIAction(title: "Move to First Gap", image: nil, attributes: [], handler: { [weak self] action in
                            guard let self = self else { return }
                            self.moveToTopGapAction(action)
                        }),
                        UIAction(title: "Move to First Protected Tweet", image: nil, attributes: [], handler: { [weak self] action in
                            guard let self = self else { return }
                            self.moveToFirstProtectedTweet(action)
                        }),
                        UIAction(title: "Move to First Protected User", image: nil, attributes: [], handler: { [weak self] action in
                            guard let self = self else { return }
                            self.moveToFirstProtectedUser(action)
                        }),
                        UIAction(title: "Drop Recent 50 Tweets", image: nil, attributes: [], handler: { [weak self] action in
                            guard let self = self else { return }
                            self.dropRecentTweetsAction(action)
                        }),
                        UIAction(title: "Enable Bottom Fetcher", image: nil, attributes: [], handler: { [weak self] action in
                            guard let self = self else { return }
                            self.enableBottomFetcher(action)
                        }),
                        UIAction(title: "Show Floaty", image: nil, attributes: [], handler: { [weak self] action in
                            guard let self = self else { return }
                            self.showFloatyButton(action)
                        })
                    ]
                )
            )
        }
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
    
        view.addSubview(floatyButton)
        
        viewModel.contentOffsetAdjustableTimelineViewControllerDelegate = self
        viewModel.tableView = tableView
        viewModel.timelinePostTableViewCellDelegate = self
        viewModel.timelineMiddleLoaderTableViewCellDelegate = self
        viewModel.setupDiffableDataSource(for: tableView)
        context.authenticationService.activeAuthenticationIndex
            .sink { [weak self] activeAuthenticationIndex in
                guard let self = self else { return }
                let predicate: NSPredicate
                if let activeAuthenticationIndex = activeAuthenticationIndex {
                    let userID = activeAuthenticationIndex.twitterAuthentication?.twitterUser?.id ?? ""
                    predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                        TimelineIndex.predicate(platform: .twitter),
                        TimelineIndex.predicate(userID: userID),
                    ])
                } else {
                    // use invalid predicate
                    predicate = TimelineIndex.predicate(userID: "")
                }
                self.viewModel.fetchedResultsController.fetchRequest.predicate = predicate
                do {
                    self.viewModel.diffableDataSource?.defaultRowAnimation = .fade
                    try self.viewModel.fetchedResultsController.performFetch()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.viewModel.diffableDataSource?.defaultRowAnimation = .automatic
                    }
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
            .store(in: &disposeBag)
        tableView.delegate = self
        tableView.dataSource = viewModel.diffableDataSource
        
        // bind refresh control
        viewModel.isFetchingLatestTimeline
            .sink { [weak self] isFetching in
                guard let self = self else { return }
                if !isFetching {
                    self.refreshControl.endRefreshing()
                }
            }
            .store(in: &disposeBag)
        context.authenticationService.activeAuthenticationIndex
            .sink { [weak self] activeAuthenticationIndex in
                guard let self = self else { return }
                let placeholderImage = UIImage
                    .placeholder(size: UIButton.avatarButtonSize, color: .systemFill)
                    .af.imageRoundedIntoCircle()
                guard let twitterUser = activeAuthenticationIndex?.twitterAuthentication?.twitterUser,
                      let avatarImageURL = twitterUser.avatarImageURL() else {
                    self.avatarButton.setImage(placeholderImage, for: .normal)
                    return
                }
                let filter = ScaledToSizeCircleFilter(size: UIButton.avatarButtonSize)
                self.avatarButton.af.setImage(
                    for: .normal,
                    url: avatarImageURL,
                    placeholderImage: placeholderImage,
                    filter: filter
                )
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
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        floatyButton.paddingY = view.safeAreaInsets.bottom + UIView.floatyButtonBottomMargin
    }

}

extension HomeTimelineViewController {
    
    @objc private func avatarButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        coordinator.present(scene: .drawerSidebar, from: self, transition: .custom(transitioningDelegate: drawerSidebarTransitionController))
    }
    
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        guard viewModel.loadLatestStateMachine.enter(HomeTimelineViewModel.LoadLatestState.Loading.self) else {
            sender.endRefreshing()
            return
        }
    }
    
    @objc private func composeFloatyButtonPressed(_ sender: FloatyItem) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        let composeTweetViewModel = ComposeTweetViewModel(context: context, repliedTweetObjectID: nil)
        coordinator.present(scene: .composeTweet(viewModel: composeTweetViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
    
    #if DEBUG
    @objc private func moveToTopGapAction(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshot = diffableDataSource.snapshot()
        let item = snapshot.itemIdentifiers.first(where: { item in
            switch item {
            case .middleLoader: return true
            default:                        return false
            }
        })
        if let targetItem = item, let index = snapshot.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
        }
    }
    
    @objc private func moveToFirstProtectedTweet(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshot = diffableDataSource.snapshot()
        let item = snapshot.itemIdentifiers.first(where: { item in
            switch item {
            case .homeTimelineIndex(let objectID, _):
                let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TimelineIndex
                guard let targetTweet = (tweet.tweet?.retweet ?? tweet.tweet) else { return false }
                return targetTweet.author.protected
            default:
                return false
            }
        })
        if let targetItem = item, let index = snapshot.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
        } else {
            print("Not found protected tweet")
        }
    }
    
    @objc private func moveToFirstProtectedUser(_ sender: UIAction) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshot = diffableDataSource.snapshot()
        let item = snapshot.itemIdentifiers.first(where: { item in
            switch item {
            case .homeTimelineIndex(let objectID, _):
                let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TimelineIndex
                guard let targetTweet = (tweet.tweet) else { return false }
                return targetTweet.author.protected
            default:
                return false
            }
        })
        if let targetItem = item, let index = snapshot.indexOfItem(targetItem) {
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
        } else {
            print("Not found protected tweet")
        }
    }
    
    @objc private func dropRecentTweetsAction(_ sender: UIAction) {
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
    
    @objc private func enableBottomFetcher(_ sender: UIAction) {
        if let last = viewModel.fetchedResultsController.fetchedObjects?.last {
            let objectID = last.objectID
            context.apiService.backgroundManagedObjectContext.performChanges {
                let object = self.context.apiService.backgroundManagedObjectContext.object(with: objectID) as! TimelineIndex
                object.update(hasMore: true)
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
    
    @objc private func showFloatyButton(_ sender: UIAction) {

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
        handleTableView(tableView, didSelectRowAt: indexPath)
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
    func navigationBar() -> UINavigationBar? {
        return navigationController?.navigationBar
    }
}


// MARK: - TimelineMiddleLoaderTableViewCellDelegate
extension HomeTimelineViewController: TimelineMiddleLoaderTableViewCellDelegate {
    func timelineMiddleLoaderTableViewCell(_ cell: TimelineMiddleLoaderTableViewCell, loadMoreButtonDidPressed button: UIButton) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .middleLoader(let upper):
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

// MARK: - MediaHostViewController
extension HomeTimelineViewController: MediaHostViewController {
    
}

// MARK: - TimelinePostTableViewCellDelegate
extension HomeTimelineViewController: TimelinePostTableViewCellDelegate { }
