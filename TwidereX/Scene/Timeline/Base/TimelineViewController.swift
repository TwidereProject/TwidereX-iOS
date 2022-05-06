//
//  TimelineViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-1-13.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import Floaty
import AppShared
import TwidereCore
import TwidereComposeUI

class TimelineViewController: UIViewController, NeedsDependency, DrawerSidebarTransitionHostViewController, MediaPreviewTransitionHostViewController {
    
    let logger = Logger(subsystem: "TimelineViewController", category: "ViewController")
    
    // MARK: NeedsDependency
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    // MARK: DrawerSidebarTransitionHostViewController
    private(set) var drawerSidebarTransitionController: DrawerSidebarTransitionController!
    let avatarBarButtonItem = AvatarBarButtonItem()
    
    // MARK: MediaPreviewTransitionHostViewController
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: TimelineViewModel!
    
    private(set) lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(TimelineViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        return refreshControl
    }()
    
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
    let publishProgressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.progressViewStyle = .bar
        progressView.tintColor = Asset.Colors.hightLight.color
        return progressView
    }()
    
    private lazy var floatyButton: Floaty = {
        let button = Floaty()
        button.plusColor = .white
        button.buttonColor = ThemeService.shared.theme.value.accentColor
        button.buttonImage = Asset.Editing.featherPen.image
        button.handleFirstItemDirectly = true
        
        let composeItem: FloatyItem = {
            let item = FloatyItem()
            item.title = L10n.Scene.Compose.Title.compose
            item.handler = { [weak self] item in
                guard let self = self else { return }
                self.floatyButtonPressed(item)
            }
            return item
        }()
        button.addItem(item: composeItem)
        
        return button
    }()

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension TimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        drawerSidebarTransitionController = DrawerSidebarTransitionController(hostViewController: self)

        view.backgroundColor = .systemBackground

        // setup avatarBarButtonItem
        if navigationController?.viewControllers.first == self {
            coordinator.$needsSetupAvatarBarButtonItem
                .receive(on: DispatchQueue.main)
                .sink { [weak self] needsSetupAvatarBarButtonItem in
                    guard let self = self else { return }
                    self.navigationItem.leftBarButtonItem = needsSetupAvatarBarButtonItem ? self.avatarBarButtonItem : nil
                }
                .store(in: &disposeBag)
        }
        avatarBarButtonItem.avatarButton.addTarget(self, action: #selector(TimelineViewController.avatarButtonPressed(_:)), for: .touchUpInside)
        avatarBarButtonItem.delegate = self
        
        // bind avatarBarButtonItem data
        Publishers.CombineLatest(
            context.authenticationService.$activeAuthenticationContext,
            viewModel.viewDidAppear.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] authenticationContext, _ in
            guard let self = self else { return }
            let user = authenticationContext?.user(in: self.context.managedObjectContext)
            self.avatarBarButtonItem.configure(user: user)
        }
        .store(in: &disposeBag)

        // layout tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.frame = view.bounds
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        // layout publish progress
        publishProgressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(publishProgressView)
        NSLayoutConstraint.activate([
            publishProgressView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            publishProgressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            publishProgressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        context.publisherService.$currentPublishProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self = self else { return }
                let progress = Float(progress)
                let withAnimation = progress > self.publishProgressView.progress
                self.publishProgressView.setProgress(progress, animated: withAnimation)
                
                if progress == 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        guard let self = self else { return }
                        self.publishProgressView.setProgress(0, animated: false)
                    }
                }
            }
            .store(in: &disposeBag)

        view.addSubview(floatyButton)
        
        tableView.delegate = self
        
        // setup refresh control
        tableView.refreshControl = refreshControl
        viewModel.didLoadLatest
            .receive(on: DispatchQueue.main, options: nil)
            .sink { [weak self] in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.5) { [weak self] in
                    guard let self = self else { return }
                    self.refreshControl.endRefreshing()
                }
            }
            .store(in: &disposeBag)
        // setup batch fetch
        viewModel.listBatchFetchViewModel.setup(scrollView: tableView)
        viewModel.listBatchFetchViewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.loadOldestStateMachine.enter(HomeTimelineViewModel.LoadOldestState.Loading.self)
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refreshControl.endRefreshing()
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.viewDidAppear.send()

        if !viewModel.isLoadingLatest {
            let now = Date()
            if let timestamp = viewModel.lastAutomaticFetchTimestamp {
                if now.timeIntervalSince(timestamp) > 60 {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): auto fetch lastest timeline…")
                    Task {
                        await viewModel.loadLatest()
                    }
                    viewModel.lastAutomaticFetchTimestamp = now
                } else {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): auto fetch lastest timeline skip. Reason: updated in recent 60s")
                }
            } else {
                Task {
                    await viewModel.loadLatest()
                }
                viewModel.lastAutomaticFetchTimestamp = now
            }
            
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { _ in
            // do nothing
        } completion: { _ in
            self.tableView.reloadData()
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): view transition to new size: \(size.debugDescription). And table reloaded")
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.floatyButton.paddingY = self.view.safeAreaInsets.bottom + UIView.floatyButtonBottomMargin
        }
    }

}

extension TimelineViewController {

    @objc private func avatarButtonPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        let drawerSidebarViewModel = DrawerSidebarViewModel(context: context)
        coordinator.present(scene: .drawerSidebar(viewModel: drawerSidebarViewModel), from: self, transition: .custom(transitioningDelegate: drawerSidebarTransitionController))
    }

    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        Task {
            await viewModel.loadLatest()
        }
    }

    @objc private func floatyButtonPressed(_ sender: FloatyItem) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let composeViewModel = ComposeViewModel(context: context)
        let composeContentViewModel = ComposeContentViewModel(
            inputContext: .post,
            configurationContext: ComposeContentViewModel.ConfigurationContext(
                apiService: context.apiService,
                authenticationService: context.authenticationService,
                mastodonEmojiService: context.mastodonEmojiService,
                statusViewConfigureContext: .init(
                    dateTimeProvider: DateTimeSwiftProvider(),
                    twitterTextProvider: OfficialTwitterTextProvider(),
                    authenticationContext: context.authenticationService.$activeAuthenticationContext
                )
            )
        )
        coordinator.present(scene: .compose(viewModel: composeViewModel, contentViewModel: composeContentViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }

}

// MARK: - UITableViewDelegate
extension TimelineViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:TimelineViewController.AutoGenerateTableViewDelegate

    // Generated using Sourcery
    // DO NOT EDIT
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        aspectTableView(tableView, didSelectRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return aspectTableView(tableView, contextMenuConfigurationForRowAt: indexPath, point: point)
    }

    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return aspectTableView(tableView, previewForHighlightingContextMenuWithConfiguration: configuration)
    }

    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return aspectTableView(tableView, previewForDismissingContextMenuWithConfiguration: configuration)
    }

    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        aspectTableView(tableView, willPerformPreviewActionForMenuWith: configuration, animator: animator)
    }

    // sourcery:end
}

// MARK: - AvatarBarButtonItemDelegate
extension TimelineViewController: AvatarBarButtonItemDelegate { }

// MARK: - ScrollViewContainer
extension TimelineViewController: ScrollViewContainer {

    var scrollView: UIScrollView { return tableView }

    func scrollToTop(animated: Bool) {
        if scrollView.contentOffset.y < scrollView.frame.height,
           !viewModel.isLoadingLatest,
           (scrollView.contentOffset.y + scrollView.adjustedContentInset.top) == 0.0,
           !refreshControl.isRefreshing {
            scrollView.scrollRectToVisible(CGRect(origin: CGPoint(x: 0, y: -refreshControl.frame.height), size: CGSize(width: 1, height: 1)), animated: animated)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.refreshControl.beginRefreshing()
                self.refreshControl.sendActions(for: .valueChanged)
            }
        } else {
            let indexPath = IndexPath(row: 0, section: 0)
            guard viewModel.diffableDataSource?.itemIdentifier(for: indexPath) != nil else { return }
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }

}

// MARK: - StatusViewTableViewCellDelegate
extension TimelineViewController: StatusViewTableViewCellDelegate { }

// MARK: - TimelineMiddleLoaderTableViewCellDelegate
extension TimelineViewController: TimelineMiddleLoaderTableViewCellDelegate {
    func timelineMiddleLoaderTableViewCell(
        _ cell: TimelineMiddleLoaderTableViewCell,
        loadMoreButtonDidPressed button: UIButton
    ) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        Task {
            await viewModel.loadMore(item: item)
        }
    }
}
