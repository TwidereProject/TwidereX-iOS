//
//  NotificationTimelineViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import TwidereUI

final class NotificationTimelineViewController: UIViewController, NeedsDependency, MediaPreviewTransitionHostViewController {

    let logger = Logger(subsystem: "NotificationTimelineViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: NotificationTimelineViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    private(set) lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(NotificationTimelineViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        return refreshControl
    }()
    
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(UserNotificationStyleTableViewCell.self, forCellReuseIdentifier: String(describing: UserNotificationStyleTableViewCell.self))
        tableView.register(TimelineMiddleLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()

}

extension NotificationTimelineViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            statusViewTableViewCellDelegate: self,
            userViewTableViewCellDelegate: self
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
                guard let snapshot = self.viewModel.diffableDataSource?.snapshot() else { return }
                guard let lastItem = snapshot.itemIdentifiers.last else { return }
                guard case .bottomLoader = lastItem else { return }
                self.viewModel.loadOldestStateMachine.enter(NotificationTimelineViewModel.LoadOldestState.Loading.self)
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshControl.endRefreshing()
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
}

extension NotificationTimelineViewController {

    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        Task {
            await viewModel.loadLatest()
        }
    }
    
}

// MARK: - UITableViewDelegate
extension NotificationTimelineViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:NotificationTimelineViewController.AutoGenerateTableViewDelegate

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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let item = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else {
            return
        }
        
        // check item type inside `loadMore`
        Task {
            await viewModel.loadMore(item: item)
        }
    }

}

// MARK: - StatusViewTableViewCellDelegate
extension NotificationTimelineViewController: StatusViewTableViewCellDelegate { }

// MARK: - UserTableViewCellDelegate
extension NotificationTimelineViewController: UserViewTableViewCellDelegate { }

// MARK: - ScrollViewContainer
extension NotificationTimelineViewController: ScrollViewContainer {
    var scrollView: UIScrollView {
        return tableView
    }
}
