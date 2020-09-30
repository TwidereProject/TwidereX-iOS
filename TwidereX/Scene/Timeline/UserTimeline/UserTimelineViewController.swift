//
//  UserTimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import os.log
import UIKit
import Combine

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
        viewModel.setupDiffableDataSource(for: tableView)
        do {
            try viewModel.fetchedResultsController.performFetch()
        } catch {
            assertionFailure(error.localizedDescription)
        }
        tableView.delegate = self
        tableView.dataSource = viewModel.diffableDataSource
                
//        viewModel.userTimelineTweets
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] tweets in
//                guard let self = self else { return }
//                let items = tweets.map { TimelineItem.userTimelineItem(tweet: $0) }
//                var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, TimelineItem>()
//                snapshot.appendSections([.main])
//                snapshot.appendItems(items, toSection: .main)
//                self.viewModel.diffableDataSource?.apply(snapshot)
//            }
//            .store(in: &disposeBag)
        
        
        viewModel.stateMachine.enter(UserTimelineViewModel.State.Reloading.self)
    }
    
}

// MARK: - UITableViewDelegate
extension UserTimelineViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        os_log("%{public}s[%{public}ld], %{public}s: indexPath %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)
//        
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
//        
//        switch item {
//        case .userTimelineItem(let tweet):
//            let managedObjectContext = self.viewModel.fetchedResultsController.managedObjectContext
//            managedObjectContext.performAndWait {
//                guard let timelineIndex = managedObjectContext.object(with: objectID) as? TimelineIndex else { return }
//                guard let tweet = timelineIndex.tweet?.retweet ?? timelineIndex.tweet else { return }
//                
//                let tweetPostViewModel = TweetPostViewModel(context: self.context, tweet: tweet)
//                self.coordinator.present(scene: .tweetPost(viewModel: tweetPostViewModel), from: self, transition: .showDetail)
//            }
//        default:
//            return
//        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? TimelineBottomLoaderTableViewCell {
            cell.activityIndicatorView.startAnimating()
            viewModel.stateMachine.enter(UserTimelineViewModel.State.LoadingMore.self)
        }
    }
    
}

// MARK: - TimelinePostTableViewCellDelegate
extension UserTimelineViewController: TimelinePostTableViewCellDelegate {
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, retweetInfoLabelDidPressed label: UILabel) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
//        switch item {
//        case .userTimelineItem(let tweet):
//            let profileViewModel = ProfileViewModel(twitterUser: tweet.userObject)
//            self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
//        default:
//            return
//        }
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, avatarImageViewDidPressed imageView: UIImageView) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
//        switch item {
//        case .userTimelineItem(let tweet):
//            let tweet = tweet.retweetObject ?? tweet
//            let profileViewModel = ProfileViewModel(twitterUser: tweet.userObject)
//            self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
//        default:
//            return
//        }
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, quoteAvatarImageViewDidPressed imageView: UIImageView) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
//        switch item {
//        case .userTimelineItem(let tweet):
//            guard let tweet = tweet.retweetObject?.quoteObject ?? tweet.quoteObject else { return }
//            let profileViewModel = ProfileViewModel(twitterUser: tweet.userObject)
//            self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
//        default:
//            return
//        }
    }
    
    
}
