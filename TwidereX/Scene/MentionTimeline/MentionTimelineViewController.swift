//
//  MentionTimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-3.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import AVKit
import Combine
import CoreData
import CoreDataStack
import TwitterAPI
import Floaty
import AlamofireImage

final class MentionTimelineViewController: UIViewController, NeedsDependency, DrawerSidebarTransitionableViewController, MediaPreviewableViewController {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = MentionTimelineViewModel(context: context)
   
    private(set) var drawerSidebarTransitionController: DrawerSidebarTransitionController!
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    let avatarButton = UIButton.avatarButton

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
            item.title = L10n.Scene.Compose.Title.compose
            item.handler = self.composeFloatyButtonPressed
            return item
        }()
        button.addItem(item: composeItem)

        return button
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension MentionTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: avatarButton)
        avatarButton.addTarget(self, action: #selector(MentionTimelineViewController.avatarButtonPressed(_:)), for: .touchUpInside)

        drawerSidebarTransitionController = DrawerSidebarTransitionController(drawerSidebarTransitionableViewController: self)
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(MentionTimelineViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        
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
                        UIAction(title: "Drop first 1 mentions", image: nil, attributes: [], handler: { [weak self] action in
                            guard let self = self else { return }
                            self.dropMentions(count: 1)
                        }),
                        UIAction(title: "Drop first 5 mentions", image: nil, attributes: [], handler: { [weak self] action in
                            guard let self = self else { return }
                            self.dropMentions(count: 5)
                        }),
                        UIAction(title: "Remove all mentions", image: nil, attributes: [], handler: { [weak self] action in
                            guard let self = self else { return }
                            self.removeAllMentions()
                        }),
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
                        MentionTimelineIndex.predicate(platform: .twitter),
                        MentionTimelineIndex.predicate(userID: userID),
                    ])
                } else {
                    // use invalid predicate
                    predicate = MentionTimelineIndex.predicate(userID: "")
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
                    UIView.animate(withDuration: 0.5) { [weak self] in
                        guard let self = self else { return }
                        self.refreshControl.endRefreshing()
                    }
                }
            }
            .store(in: &disposeBag)
        Publishers.CombineLatest(
            context.authenticationService.activeAuthenticationIndex.eraseToAnyPublisher(),
            viewModel.viewDidAppear.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] activeAuthenticationIndex, _ in
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
        
        viewModel.viewDidAppear.send()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if (self.viewModel.fetchedResultsController.fetchedObjects ?? []).count == 0 {
                self.viewModel.loadLatestStateMachine.enter(MentionTimelineViewModel.LoadLatestState.Loading.self)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        context.videoPlaybackService.viewDidDisappear(from: self)
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

extension MentionTimelineViewController {
    
    @objc private func avatarButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        coordinator.present(scene: .drawerSidebar, from: self, transition: .custom(transitioningDelegate: drawerSidebarTransitionController))
    }
    
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        guard viewModel.loadLatestStateMachine.enter(MentionTimelineViewModel.LoadLatestState.Loading.self) else {
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
    @objc private func removeAllMentions() {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        let mentionTimelineIndexes = viewModel.fetchedResultsController.fetchedObjects ?? []
        let droppingObjectIDs = mentionTimelineIndexes.map { $0.objectID }
        context.apiService.backgroundManagedObjectContext.performChanges {
            for objectID in droppingObjectIDs {
                guard let object = try? self.context.apiService.backgroundManagedObjectContext.existingObject(with: objectID) as? MentionTimelineIndex else { continue }
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
    
    @objc private func dropMentions(count: Int) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        let mentionTimelineIndexes = viewModel.fetchedResultsController.fetchedObjects ?? []
        let droppingObjectIDs = mentionTimelineIndexes.prefix(count).map { $0.objectID }
        context.apiService.backgroundManagedObjectContext.performChanges {
            for objectID in droppingObjectIDs {
                guard let object = try? self.context.apiService.backgroundManagedObjectContext.existingObject(with: objectID) as? MentionTimelineIndex else { continue }
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
    #endif

}

// MARK: - UIScrollViewDelegate
extension MentionTimelineViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        let cells = tableView.visibleCells.compactMap { $0 as? TimelineBottomLoaderTableViewCell }
        guard let loaderTableViewCell = cells.first else { return }

        if let tabBar = tabBarController?.tabBar, let window = view.window {
            let loaderTableViewCellFrameInWindow = tableView.convert(loaderTableViewCell.frame, to: nil)
            let windowHeight = window.frame.height
            let loaderAppear = (loaderTableViewCellFrameInWindow.origin.y + 0.8 * loaderTableViewCell.frame.height) < (windowHeight - tabBar.frame.height)
            if loaderAppear {
                viewModel.loadoldestStateMachine.enter(MentionTimelineViewModel.LoadOldestState.Loading.self)
            }
        } else {
            viewModel.loadoldestStateMachine.enter(MentionTimelineViewModel.LoadOldestState.Loading.self)
        }
    }
}

// MARK: - UITableViewDelegate
extension MentionTimelineViewController: UITableViewDelegate {

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
        case .mentionTimelineIndex(let objectID, _):
            let managedObjectContext = self.viewModel.fetchedResultsController.managedObjectContext
            managedObjectContext.performAndWait {
                guard let mentionTimelineIndex = managedObjectContext.object(with: objectID) as? MentionTimelineIndex else { return }
                guard let tweet = mentionTimelineIndex.tweet?.retweet ?? mentionTimelineIndex.tweet else { return }

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
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        handleTableView(tableView, contextMenuConfigurationForRowAt: indexPath, point: point)
    }
    
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        handleTableView(tableView, previewForHighlightingContextMenuWithConfiguration: configuration)
    }
    
    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        handleTableView(tableView, previewForDismissingContextMenuWithConfiguration: configuration)
    }
    
    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        handleTableView(tableView, willPerformPreviewActionForMenuWith: configuration, animator: animator)
    }

}

// MARK: - ContentOffsetAdjustableTimelineViewControllerDelegate
extension MentionTimelineViewController: ContentOffsetAdjustableTimelineViewControllerDelegate {
    func navigationBar() -> UINavigationBar? {
        return navigationController?.navigationBar
    }
}

// MARK: - TimelineMiddleLoaderTableViewCellDelegate
extension MentionTimelineViewController: TimelineMiddleLoaderTableViewCellDelegate {
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
            stateMachine.enter(MentionTimelineViewModel.LoadMiddleState.Loading.self)
        default:
            assertionFailure()
        }
    }
}

// MARK: - AVPlayerViewControllerDelegate
extension MentionTimelineViewController: AVPlayerViewControllerDelegate {
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        handlePlayerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        handlePlayerViewController(playerViewController, willEndFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
    
}

// MARK: - TimelinePostTableViewCellDelegate
extension MentionTimelineViewController: TimelinePostTableViewCellDelegate {
    weak var playerViewControllerDelegate: AVPlayerViewControllerDelegate? { return self }
    func parent() -> UIViewController { return self }
}

// MARK: - ScrollViewContainer
extension MentionTimelineViewController: ScrollViewContainer {
    
    var scrollView: UIScrollView { return tableView }
    
    func scrollToTop(animated: Bool) {
        if viewModel.loadLatestStateMachine.canEnterState(MentionTimelineViewModel.LoadLatestState.Loading.self),
           (scrollView.contentOffset.y + scrollView.adjustedContentInset.top) == 0.0,
           !refreshControl.isRefreshing {
            scrollView.scrollRectToVisible(CGRect(origin: CGPoint(x: 0, y: -refreshControl.frame.height), size: CGSize(width: 1, height: 1)), animated: animated)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.refreshControl.beginRefreshing()
                self.refreshControl.sendActions(for: .valueChanged)
            }
        } else {
            scrollView.scrollRectToVisible(CGRect(origin: .zero, size: CGSize(width: 1, height: 1)), animated: animated)
        }
    }
    
}
