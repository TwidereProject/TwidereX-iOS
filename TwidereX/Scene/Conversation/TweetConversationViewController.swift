//
//  TweetConversationViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-15.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import TwitterAPI

final class TweetConversationViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: TweetConversationViewModel!
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ConversationPostTableViewCell.self, forCellReuseIdentifier: String(describing: ConversationPostTableViewCell.self))
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

extension TweetConversationViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        viewModel.contentOffsetAdjustableTimelineViewControllerDelegate = self
        viewModel.tableView = tableView
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.backgroundColor = .systemBackground
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        
        viewModel.conversationPostTableViewCellDelegate = self
        viewModel.timelinePostTableViewCellDelegate = self
        viewModel.setupDiffableDataSource(for: tableView)
        tableView.delegate = self
        tableView.dataSource = viewModel.diffableDataSource
        tableView.reloadData()
        
        viewModel.loadConversationStateMachine.enter(TweetConversationViewModel.LoadConversationState.Prepare.self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

// MARK: - UIScrollViewDelegate
extension TweetConversationViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        let cells = tableView.visibleCells.compactMap { $0 as? TimelineBottomLoaderTableViewCell }
        guard let loaderTableViewCell = cells.first else { return }
        
        if let tabBar = tabBarController?.tabBar, let window = view.window {
            let loaderTableViewCellFrameInWindow = tableView.convert(loaderTableViewCell.frame, to: nil)
            let windowHeight = window.frame.height
            let loaderAppear = (loaderTableViewCellFrameInWindow.origin.y + 0.8 * loaderTableViewCell.frame.height) < (windowHeight - tabBar.frame.height)
            if loaderAppear {
                viewModel.loadConversationStateMachine.enter(TweetConversationViewModel.LoadConversationState.Loading.self)
            }
        } else {
            viewModel.loadConversationStateMachine.enter(TweetConversationViewModel.LoadConversationState.Loading.self)
        }
    }
}

// MARK: - UITableViewDelegate
extension TweetConversationViewController: UITableViewDelegate {
    
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
        case .leaf(let objectID, _):
            let managedObjectContext = context.managedObjectContext
            managedObjectContext.perform {
                guard let tweet = managedObjectContext.object(with: objectID) as? Tweet else { return }
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let tweetPostViewModel = TweetConversationViewModel(context: self.context, tweetObjectID: tweet.objectID)
                    self.coordinator.present(scene: .tweetConversation(viewModel: tweetPostViewModel), from: self, transition: .show)
                }
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

// MARK: - ConversationPostTableViewCellDelegate
extension TweetConversationViewController: ConversationPostTableViewCellDelegate {
    
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, avatarImageViewDidPressed imageView: UIImageView) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        guard case let .root(objectID) = viewModel.rootItem else { return }
        context.managedObjectContext.perform { [weak self] in
            guard let self = self else { return }
            guard let tweet = self.context.managedObjectContext.object(with: objectID) as? Tweet else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let profileViewModel = ProfileViewModel(twitterUser: tweet.author)
                self.context.authenticationService.activeAuthenticationIndex
                    .map { $0?.twitterAuthentication?.twitterUser }
                    .assign(to: \.value, on: profileViewModel.currentTwitterUser)
                    .store(in: &profileViewModel.disposeBag)
                self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
            }
        }
    }
    
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, quoteAvatarImageViewDidPressed imageView: UIImageView) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        guard case let .root(objectID) = viewModel.rootItem else { return }
        context.managedObjectContext.perform { [weak self] in
            guard let self = self else { return }
            guard let tweet = self.context.managedObjectContext.object(with: objectID) as? Tweet else { return }
            guard let targetTweet = tweet.retweet?.quote ?? tweet.quote else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let profileViewModel = ProfileViewModel(twitterUser: targetTweet.author)
                self.context.authenticationService.activeAuthenticationIndex
                    .map { $0?.twitterAuthentication?.twitterUser }
                    .assign(to: \.value, on: profileViewModel.currentTwitterUser)
                    .store(in: &profileViewModel.disposeBag)
                self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
            }
        }
    }
        
}

// MARK: - ContentOffsetAdjustableTimelineViewControllerDelegate
extension TweetConversationViewController: ContentOffsetAdjustableTimelineViewControllerDelegate {
    func navigationBar() -> UINavigationBar? {
        return navigationController?.navigationBar
    }
}
