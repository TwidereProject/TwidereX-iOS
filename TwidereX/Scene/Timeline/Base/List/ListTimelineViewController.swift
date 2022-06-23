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
import TabBarPager

class ListTimelineViewController: TimelineViewController {
    
    var viewModel: ListTimelineViewModel! {
        get {
            return _viewModel as? ListTimelineViewModel
        }
        set {
            _viewModel = newValue
        }
    }
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
    let cellFrameCache = NSCache<NSNumber, NSValue>()

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ListTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        tableView.delegate = self
        
        // setup refresh control
        viewModel.$isRefreshControlEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRefreshControlEnabled in
                guard let self = self else { return }
                self.tableView.refreshControl = isRefreshControlEnabled ? self.refreshControl : nil
            }
            .store(in: &disposeBag)
        
        // setup batch fetch
        viewModel.listBatchFetchViewModel.setup(scrollView: tableView)
        viewModel.listBatchFetchViewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard self.isDisplaying else { return }
                self.viewModel.stateMachine.enter(TimelineViewModel.LoadOldestState.Loading.self)
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // FIXME: use timer to auto refresh
        autoFetchLatest()
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
    
}

extension ListTimelineViewController {
    
    public func reload() {
        Task {
            self.viewModel.stateMachine.enter(ListTimelineViewModel.LoadOldestState.Reloading.self)
        }   // end Task
    }
    
    private func autoFetchLatest() {
        guard viewModel.enableAutoFetchLatest else { return }
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        guard let diffableDataSource = viewModel.diffableDataSource,
              !diffableDataSource.snapshot().itemIdentifiers.isEmpty        // conflict with LoadOldestState
        else { return }
        
        if !viewModel.isLoadingLatest {
            let now = Date()
            if let timestamp = viewModel.lastAutomaticFetchTimestamp {
                if now.timeIntervalSince(timestamp) > 60 {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Timeline] auto fetch lastest timeline…")
                    Task {
                        await _viewModel.loadLatest()
                    }
                    viewModel.lastAutomaticFetchTimestamp = now
                } else {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Timeline] auto fetch lastest timeline skip. Reason: updated in recent 60s")
                }
            } else {
                Task {
                    await self.viewModel.loadLatest()
                }
                viewModel.lastAutomaticFetchTimestamp = now
            }
        }
    }   // end func
    
}

// MARK: - CellFrameCacheContainer
extension ListTimelineViewController: CellFrameCacheContainer {
    func keyForCache(tableView: UITableView, indexPath: IndexPath) -> NSNumber? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return nil }
        let key = NSNumber(value: item.hashValue)
        return key
    }
}

// MARK: - UITableViewDelegate
extension ListTimelineViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:ListTimelineView
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
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let frame = retrieveCellFrame(tableView: tableView, indexPath: indexPath) else {
            return 200
        }
        return ceil(frame.height)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cacheCellFrame(tableView: tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }
}

// MARK: - ScrollViewContainer
extension ListTimelineViewController: ScrollViewContainer {

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
extension ListTimelineViewController: StatusViewTableViewCellDelegate { }

// MARK: - TimelineMiddleLoaderTableViewCellDelegate
extension ListTimelineViewController: TimelineMiddleLoaderTableViewCellDelegate {
    func timelineMiddleLoaderTableViewCell(
        _ cell: TimelineMiddleLoaderTableViewCell,
        loadMoreButtonDidPressed button: UIButton
    ) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        Task {
            await self.viewModel.loadMore(item: item)
        }
    }
}

// MARK: - TabBarPage
extension ListTimelineViewController: TabBarPage {
    var pageScrollView: UIScrollView {
        scrollView
    }
}

