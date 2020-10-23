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
import Floaty

final class HomeTimelineViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = HomeTimelineViewModel(context: context)
    
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
        context.authenticationService.currentTwitterUser
            .assign(to: \.value, on: viewModel.currentTwitterUser)
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
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        floatyButton.paddingY = view.safeAreaInsets.bottom + UIView.floatyButtonBottomMargin
    }

}

extension HomeTimelineViewController {
    
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
            case .homeTimelineMiddleLoader: return true
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
                let timelineIndex = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TimelineIndex
                guard let targetTweet = (timelineIndex.tweet?.retweet ?? timelineIndex.tweet) else { return false }
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
                let timelineIndex = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TimelineIndex
                guard let targetTweet = (timelineIndex.tweet) else { return false }
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
                self.coordinator.present(scene: .tweetConversation(viewModel: tweetPostViewModel), from: self, transition: .show)
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
    func navigationBar() -> UINavigationBar? {
        return navigationController?.navigationBar
    }
}

extension HomeTimelineViewController {
    
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
                let twitterUser = tweet.author
                let profileViewModel = ProfileViewModel(twitterUser: twitterUser)
                self.context.authenticationService.currentTwitterUser
                    .assign(to: \.value, on: profileViewModel.currentTwitterUser).store(in: &profileViewModel.disposeBag)
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
                let twitterUser = tweet.author
                let profileViewModel = ProfileViewModel(twitterUser: twitterUser)
                self.context.authenticationService.currentTwitterUser
                    .assign(to: \.value, on: profileViewModel.currentTwitterUser).store(in: &profileViewModel.disposeBag)
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
                let twitterUser = tweet.author
                let profileViewModel = ProfileViewModel(twitterUser: twitterUser)
                self.context.authenticationService.currentTwitterUser
                    .assign(to: \.value, on: profileViewModel.currentTwitterUser).store(in: &profileViewModel.disposeBag)
                self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
            }
        default:
            return
        }
    }
    
    // MARK: - ActionToolbar
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, replayButtonDidPressed sender: UIButton) {
        // retrieve target tweet infos
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let timelineItem = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .homeTimelineIndex(timelineIndexObjectID, _) = timelineItem else { return }
        let timelineIndex = viewModel.fetchedResultsController.managedObjectContext.object(with: timelineIndexObjectID) as! TimelineIndex
        guard let tweet = (timelineIndex.tweet?.retweet ?? timelineIndex.tweet) else { return }
        let tweetObjectID = tweet.objectID
        
        let composeTweetViewModel = ComposeTweetViewModel(context: context, repliedTweetObjectID: tweetObjectID)
        coordinator.present(scene: .composeTweet(viewModel: composeTweetViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, retweetButtonDidPressed sender: UIButton) {
        // prepare authentication
        guard let twitterAuthentication = viewModel.currentTwitterAuthentication.value,
              let authorization = try? twitterAuthentication.authorization(appSecret: AppSecret.shared) else {
            assertionFailure()
            return
        }
        
        // prepare current user infos
        guard let _currentTwitterUser = context.authenticationService.currentTwitterUser.value else {
            assertionFailure()
            return
        }
        let twitterUserID = twitterAuthentication.userID
        assert(_currentTwitterUser.id == twitterUserID)
        let twitterUserObjectID = _currentTwitterUser.objectID
        
        // retrieve target tweet infos
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let timelineItem = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .homeTimelineIndex(timelineIndexObjectID, _) = timelineItem else { return }
        let timelineIndex = viewModel.fetchedResultsController.managedObjectContext.object(with: timelineIndexObjectID) as! TimelineIndex
        guard let tweet = timelineIndex.tweet else { return }
        let tweetObjectID = tweet.objectID
        
        let targetRetweetKind: Twitter.API.Statuses.RetweetKind = {
            let targetTweet = (tweet.retweet ?? tweet)
            let isRetweeted = targetTweet.retweetBy.flatMap { $0.contains(where: { $0.id == twitterUserID }) } ?? false
            return isRetweeted ? .unretweet : .retweet
        }()
        
        // trigger like action
        let generator = UIImpactFeedbackGenerator(style: .light)
        let responseFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        context.apiService.retweet(
            tweetObjectID: tweetObjectID,
            twitterUserObjectID: twitterUserObjectID,
            retweetKind: targetRetweetKind,
            authorization: authorization,
            twitterUserID: twitterUserID
        )
        .receive(on: DispatchQueue.main)
        .handleEvents { _ in
            generator.prepare()
            responseFeedbackGenerator.prepare()
        } receiveOutput: { _ in
            generator.impactOccurred()
        } receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                // TODO: handle error
                break
            case .finished:
                os_log("%{public}s[%{public}ld], %{public}s: [Retweet] update local tweet retweet status to: %s", ((#file as NSString).lastPathComponent), #line, #function, targetRetweetKind == .retweet ? "retweet" : "unretweet")

                // reload item
                DispatchQueue.main.async {
                    var snapshot = diffableDataSource.snapshot()
                    snapshot.reloadItems([timelineItem])
                    diffableDataSource.defaultRowAnimation = .none
                    diffableDataSource.apply(snapshot)
                    diffableDataSource.defaultRowAnimation = .automatic
                }
            }
        }
        .map { targetTweetID in
            self.context.apiService.retweet(
                tweetID: targetTweetID,
                retweetKind: targetRetweetKind,
                authorization: authorization,
                twitterUserID: twitterUserID
            )
        }
        .switchToLatest()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            guard let self = self else { return }
            if self.view.window != nil, (self.tableView.indexPathsForVisibleRows ?? []).contains(indexPath) {
                responseFeedbackGenerator.impactOccurred()
            }
            switch completion {
            case .failure(let error):
                os_log("%{public}s[%{public}ld], %{public}s: [Retweet] remote retweet request fail: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            case .finished:
                os_log("%{public}s[%{public}ld], %{public}s: [Retweet] remote retweet request success", ((#file as NSString).lastPathComponent), #line, #function)
            }
        } receiveValue: { response in
            
        }
        .store(in: &disposeBag)
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, favoriteButtonDidPressed sender: UIButton) {
        // prepare authentication
        guard let twitterAuthentication = viewModel.currentTwitterAuthentication.value,
              let authorization = try? twitterAuthentication.authorization(appSecret: AppSecret.shared) else {
            assertionFailure()
            return
        }
        
        // prepare current user infos
        guard let _currentTwitterUser = context.authenticationService.currentTwitterUser.value else {
            assertionFailure()
            return
        }
        let twitterUserID = twitterAuthentication.userID
        assert(_currentTwitterUser.id == twitterUserID)
        let twitterUserObjectID = _currentTwitterUser.objectID
        
        // retrieve target tweet infos
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let timelineItem = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .homeTimelineIndex(timelineIndexObjectID, _) = timelineItem else { return }
        let timelineIndex = viewModel.fetchedResultsController.managedObjectContext.object(with: timelineIndexObjectID) as! TimelineIndex
        guard let tweet = timelineIndex.tweet else { return }
        let tweetObjectID = tweet.objectID

        let targetFavoriteKind: Twitter.API.Favorites.FavoriteKind = {
            let targetTweet = (tweet.retweet ?? tweet)
            let isLiked = targetTweet.likeBy.flatMap { $0.contains(where: { $0.id == twitterUserID }) } ?? false
            return isLiked ? .destroy : .create
        }()

        // trigger like action
        let generator = UIImpactFeedbackGenerator(style: .light)
        let responseFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        context.apiService.like(
            tweetObjectID: tweetObjectID,
            twitterUserObjectID: twitterUserObjectID,
            favoriteKind: targetFavoriteKind,
            authorization: authorization,
            twitterUserID: twitterUserID
        )
        .receive(on: DispatchQueue.main)
        .handleEvents { _ in
            generator.prepare()
            responseFeedbackGenerator.prepare()
        } receiveOutput: { _ in
            generator.impactOccurred()
        } receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                // TODO: handle error
                break
            case .finished:
                os_log("%{public}s[%{public}ld], %{public}s: [Like] update local tweet like status to: %s", ((#file as NSString).lastPathComponent), #line, #function, targetFavoriteKind == .create ? "like" : "unlike")

                // reload item
                DispatchQueue.main.async {
                    var snapshot = diffableDataSource.snapshot()
                    snapshot.reloadItems([timelineItem])
                    diffableDataSource.defaultRowAnimation = .none
                    diffableDataSource.apply(snapshot)
                    diffableDataSource.defaultRowAnimation = .automatic
                }
            }
        }
        .map { targetTweetID in
            self.context.apiService.like(
                tweetID: targetTweetID,
                favoriteKind: targetFavoriteKind,
                authorization: authorization,
                twitterUserID: twitterUserID
            )
        }
        .switchToLatest()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            guard let self = self else { return }
            if self.view.window != nil, (self.tableView.indexPathsForVisibleRows ?? []).contains(indexPath) {
                responseFeedbackGenerator.impactOccurred()
            }
            switch completion {
            case .failure(let error):
                os_log("%{public}s[%{public}ld], %{public}s: [Like] remote like request fail: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            case .finished:
                os_log("%{public}s[%{public}ld], %{public}s: [Like] remote like request success", ((#file as NSString).lastPathComponent), #line, #function)
            }
        } receiveValue: { response in
            
        }
        .store(in: &disposeBag)
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, shareButtonDidPressed sender: UIButton) {
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
