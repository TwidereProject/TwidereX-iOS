//
//  UserTimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import os.log
import UIKit
import Combine
import CoreDataStack

final class UserTimelineViewController: UIViewController, CustomTableViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: UserTimelineViewModel!
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(TimelinePostTableViewCell.self, forCellReuseIdentifier: String(describing: TimelinePostTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension UserTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.backgroundColor = .systemBackground
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        viewModel.timelinePostTableViewCellDelegate = self
        viewModel.tableView = tableView
        viewModel.setupDiffableDataSource(for: tableView)
        do {
            try viewModel.fetchedResultsController.performFetch()
        } catch {
            assertionFailure(error.localizedDescription)
        }
        tableView.delegate = self
        tableView.dataSource = viewModel.diffableDataSource
        
        viewModel.stateMachine.enter(UserTimelineViewModel.State.Reloading.self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

// MARK: - UIScrollViewDelegate
extension UserTimelineViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        let cells = tableView.visibleCells.compactMap { $0 as? TimelineBottomLoaderTableViewCell }
        guard let loaderTableViewCell = cells.first else { return }
        
        if let tabBar = tabBarController?.tabBar, let window = view.window {
            let loaderTableViewCellFrameInWindow = tableView.convert(loaderTableViewCell.frame, to: nil)
            let windowHeight = window.frame.height
            let loaderAppear = (loaderTableViewCellFrameInWindow.origin.y + 0.8 * loaderTableViewCell.frame.height) < (windowHeight - tabBar.frame.height)
            if loaderAppear {
                viewModel.stateMachine.enter(UserTimelineViewModel.State.LoadingMore.self)
            }
        } else {
            viewModel.stateMachine.enter(UserTimelineViewModel.State.LoadingMore.self)
        }
    }
}

// MARK: - UITableViewDelegate
extension UserTimelineViewController: UITableViewDelegate {
    
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
        case .userTimelineItem(let objectID):
            let managedObjectContext = self.viewModel.fetchedResultsController.managedObjectContext
            managedObjectContext.performAndWait {
                guard let tweet = managedObjectContext.object(with: objectID) as? Tweet else { return }
                let targetTweet = tweet.retweet ?? tweet
                let tweetPostViewModel = TweetConversationViewModel(context: self.context, tweetObjectID: targetTweet.objectID)
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

// MARK: - TimelinePostTableViewCellDelegate
extension UserTimelineViewController: TimelinePostTableViewCellDelegate {
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, retweetInfoLabelDidPressed label: UILabel) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .userTimelineItem(let objectID):
            viewModel.fetchedResultsController.managedObjectContext.performAndWait {
                guard let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as? Tweet else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let profileViewModel = ProfileViewModel(twitterUser: tweet.user)        // tweet's user is target retweet user
                    self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
                }
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
        case .userTimelineItem(let objectID):
            viewModel.fetchedResultsController.managedObjectContext.performAndWait {
                guard let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as? Tweet else { return }
                let targetTweet = tweet.retweet ?? tweet
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let profileViewModel = ProfileViewModel(twitterUser: targetTweet.user)
                    self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
                }
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
        case .userTimelineItem(let objectID):
            viewModel.fetchedResultsController.managedObjectContext.performAndWait {
                guard let tweet = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as? Tweet else { return }
                guard let targetTweet = tweet.retweet?.quote ?? tweet.quote else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let profileViewModel = ProfileViewModel(twitterUser: targetTweet.user)
                    self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
                }
            }
        default:
            return
        }
    }
    
    
}
