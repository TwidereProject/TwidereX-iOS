//
//  HomeTimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-1.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import AVKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import TwitterSDK
import Floaty
import AlamofireImage
import AppShared
import TwidereUI
import TwidereComposeUI

final class HomeTimelineViewController: UIViewController, NeedsDependency, DrawerSidebarTransitionHostViewController, MediaPreviewTransitionHostViewController {
    
//    var avatarBarButtonItem: AvatarBarButtonItem
    
    let logger = Logger(subsystem: "HomeTimelineViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = HomeTimelineViewModel(context: context)
    
    private(set) var drawerSidebarTransitionController: DrawerSidebarTransitionController!
    let avatarBarButtonItem = AvatarBarButtonItem()
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    private(set) lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(HomeTimelineViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        return refreshControl
    }()
    
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(TimelineMiddleLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
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

extension HomeTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        drawerSidebarTransitionController = DrawerSidebarTransitionController(hostViewController: self)

        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = avatarBarButtonItem
        avatarBarButtonItem.avatarButton.addTarget(self, action: #selector(HomeTimelineViewController.avatarButtonPressed(_:)), for: .touchUpInside)
        Publishers.CombineLatest(
            context.authenticationService.activeAuthenticationContext,
            viewModel.viewDidAppear.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] authenticationContext, _ in
            guard let self = self else { return }
            let user = authenticationContext?.user(in: self.context.managedObjectContext)
            self.avatarBarButtonItem.configure(user: user)
        }
        .store(in: &disposeBag)

        #if DEBUG
        navigationItem.rightBarButtonItem = debugActionBarButtonItem
        #endif

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.frame = view.bounds
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        view.addSubview(floatyButton)
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            statusViewTableViewCellDelegate: self,
            timelineMiddleLoaderTableViewCellDelegate: self
        )
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

//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            if (self.viewModel.fetchedResultsController.fetchedObjects ?? []).count == 0 {
//                self.viewModel.loadLatestStateMachine.enter(HomeTimelineViewModel.LoadLatestState.Loading.self)
//            }
//        }
    }

//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//
//        context.videoPlaybackService.viewDidDisappear(from: self)
//    }

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

extension HomeTimelineViewController {

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
                dateTimeProvider: DateTimeSwiftProvider(),
                twitterTextProvider: OfficialTwitterTextProvider()
            )
        )
        coordinator.present(scene: .compose(viewModel: composeViewModel, contentViewModel: composeContentViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }

}

// MARK: - UITableViewDelegate
extension HomeTimelineViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:HomeTimelineViewController.AutoGenerateTableViewDelegate

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
    
//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        guard let diffableDataSource = viewModel.diffableDataSource else { return 100 }
//        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return 100 }
//
//        guard let frame = viewModel.cellFrameCache.object(forKey: NSNumber(value: item.hashValue))?.cgRectValue else {
//            return 200
//        }
//        // os_log("%{public}s[%{public}ld], %{public}s: cache cell frame %s", ((#file as NSString).lastPathComponent), #line, #function, frame.debugDescription)
//
//        return ceil(frame.height)
//    }
//
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        handleTableView(tableView, willDisplay: cell, forRowAt: indexPath)
//    }
//
//    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        handleTableView(tableView, didEndDisplaying: cell, forRowAt: indexPath)
//
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
//
//        let key = item.hashValue
//        let frame = cell.frame
//        viewModel.cellFrameCache.setObject(NSValue(cgRect: frame), forKey: NSNumber(value: key))
//    }

}

// MARK: - ScrollViewContainer
extension HomeTimelineViewController: ScrollViewContainer {

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
extension HomeTimelineViewController: StatusViewTableViewCellDelegate { }

// MARK: - TimelineMiddleLoaderTableViewCellDelegate
extension HomeTimelineViewController: TimelineMiddleLoaderTableViewCellDelegate {
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
