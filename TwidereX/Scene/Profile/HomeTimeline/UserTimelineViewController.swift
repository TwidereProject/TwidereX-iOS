//
//  UserTimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import os.log
import UIKit
import AVKit
import Combine
import CoreDataStack
import GameplayKit
import TabBarPager

final class UserTimelineViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    let logger = Logger(subsystem: "UserTimelineViewController", category: "ViewController")
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: UserTimelineViewModel!
    
//    let mediaPreviewTransitionController = MediaPreviewTransitionController()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        // tableView.register(TimelineHeaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineHeaderTableViewCell.self))
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    let cellFrameCache = NSCache<NSNumber, NSValue>()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension UserTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.backgroundColor = .systemBackground
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            statusViewTableViewCellDelegate: self
        )
        
        // setup batch fetch
        viewModel.listBatchFetchViewModel.setup(scrollView: tableView)
        viewModel.listBatchFetchViewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.stateMachine.enter(UserTimelineViewModel.State.LoadingMore.self)
            }
            .store(in: &disposeBag)
        
        // trigger loading
        viewModel.$userIdentifier
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.stateMachine.enter(UserTimelineViewModel.State.Reloading.self)
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
//        context.videoPlaybackService.viewDidDisappear(from: self)
    }
    
}

// MARK: - UIScrollViewDelegate
//extension UserTimelineViewController {
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        handleScrollViewDidScroll(scrollView)
//    }
//
//}

// MARK: - CellFrameCacheContainer
extension UserTimelineViewController: CellFrameCacheContainer {
    func keyForCache(tableView: UITableView, indexPath: IndexPath) -> NSNumber? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return nil }
        let key = NSNumber(value: item.hashValue)
        return key
    }
}

// MARK: - UITableViewDelegate
extension UserTimelineViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:UserTimelineViewController.AutoGenerateTableViewDelegate

    // Generated using Sourcery
    // DO NOT EDIT
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            aspectTableView(tableView, didSelectRowAt: indexPath)
        }
    // sourcery:end

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let frame = retrieveCellFrame(tableView: tableView, indexPath: indexPath) else {
            return 200
        }
        return ceil(frame.height)
    }

//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        handleTableView(tableView, willDisplay: cell, forRowAt: indexPath)
//    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cacheCellFrame(tableView: tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }
//
//    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
//        handleTableView(tableView, contextMenuConfigurationForRowAt: indexPath, point: point)
//    }
//
//    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
//        handleTableView(tableView, previewForHighlightingContextMenuWithConfiguration: configuration)
//    }
//
//    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
//        handleTableView(tableView, previewForDismissingContextMenuWithConfiguration: configuration)
//    }
//
//    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
//        handleTableView(tableView, willPerformPreviewActionForMenuWith: configuration, animator: animator)
//    }
    
}

// MARK: - AVPlayerViewControllerDelegate
extension UserTimelineViewController: AVPlayerViewControllerDelegate {
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        handlePlayerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        handlePlayerViewController(playerViewController, willEndFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
    
}

// MARK: - TimelinePostTableViewCellDelegate
//extension UserTimelineViewController: TimelinePostTableViewCellDelegate {
//    weak var playerViewControllerDelegate: AVPlayerViewControllerDelegate? { return self }
//    func parent() -> UIViewController { return self }
//}
//
//// MARK: - TimelineHeaderTableViewCellDelegate
//extension UserTimelineViewController: TimelineHeaderTableViewCellDelegate { }


// MARK: - CustomScrollViewContainerController
extension UserTimelineViewController: ScrollViewContainer {
    var scrollView: UIScrollView { return tableView }
}

// MARK: - TabBarPage
extension UserTimelineViewController: TabBarPage {
    var pageScrollView: UIScrollView {
        scrollView
    }
}

//// MARK: - LoadMoreConfigurableTableViewContainer
//extension UserTimelineViewController: LoadMoreConfigurableTableViewContainer {
//    typealias BottomLoaderTableViewCell = TimelineBottomLoaderTableViewCell
//    typealias LoadingState = UserTimelineViewModel.State.LoadingMore
//
//    var loadMoreConfigurableTableView: UITableView { return tableView }
//    var loadMoreConfigurableStateMachine: GKStateMachine { return viewModel.stateMachine }
//}

// MARK: - StatusViewTableViewCellDelegate
extension UserTimelineViewController: StatusViewTableViewCellDelegate { }
