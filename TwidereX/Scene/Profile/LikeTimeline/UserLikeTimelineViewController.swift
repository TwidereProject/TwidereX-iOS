//
//  UserLikeTimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-4.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import AVKit
import Combine
import CoreDataStack
import GameplayKit

final class UserLikeTimelineViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: UserLikeTimelineViewModel!
    
//    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(TimelinePostTableViewCell.self, forCellReuseIdentifier: String(describing: TimelinePostTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.register(TimelineHeaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineHeaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension UserLikeTimelineViewController {
    
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
        
//        viewModel.tableView = tableView
//        tableView.delegate = self
//        viewModel.setupDiffableDataSource(
//            for: tableView,
//            dependency: self,
//            timelinePostTableViewCellDelegate: self,
//            timelineHeaderTableViewCellDelegate: self
//        )
//
//        // trigger timeline loading
//        viewModel.userID
//            .removeDuplicates()
//            .sink { [weak self] _ in
//                guard let self = self else { return }
//                self.viewModel.stateMachine.enter(UserLikeTimelineViewModel.State.Reloading.self)
//            }
//            .store(in: &disposeBag)
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
extension UserLikeTimelineViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScrollViewDidScroll(scrollView)
    }
}

// MARK: - UITableViewDelegate
extension UserLikeTimelineViewController: UITableViewDelegate {
    
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
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        handleTableView(tableView, didSelectRowAt: indexPath)
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
//    
}

// MARK: - AVPlayerViewControllerDelegate
extension UserLikeTimelineViewController: AVPlayerViewControllerDelegate {
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        handlePlayerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        handlePlayerViewController(playerViewController, willEndFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
    
}

// MARK: - TimelinePostTableViewCellDelegate
//extension UserLikeTimelineViewController: TimelinePostTableViewCellDelegate {
//    weak var playerViewControllerDelegate: AVPlayerViewControllerDelegate? { return self }
//    func parent() -> UIViewController { return self }
//}

// MARK: - TimelineHeaderTableViewCellDelegate
extension UserLikeTimelineViewController: TimelineHeaderTableViewCellDelegate { }

// MARK: - CustomScrollViewContainerController
extension UserLikeTimelineViewController: ScrollViewContainer {
    var scrollView: UIScrollView {
        return tableView
    }
}

// MARK: - LoadMoreConfigurableTableViewContainer
extension UserLikeTimelineViewController: LoadMoreConfigurableTableViewContainer {
    typealias BottomLoaderTableViewCell = TimelineBottomLoaderTableViewCell
    typealias LoadingState = UserLikeTimelineViewModel.State.LoadingMore
    
    var loadMoreConfigurableTableView: UITableView { return tableView }
    var loadMoreConfigurableStateMachine: GKStateMachine { return viewModel.stateMachine }
}
