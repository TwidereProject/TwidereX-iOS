//
//  UserMediaTimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-4.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TabBarPager

final class UserMediaTimelineViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()

    let logger = Logger(subsystem: "UserMediaTimelineViewController", category: "ViewController")
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: UserMediaTimelineViewModel!
    
    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UserMediaTimelineViewController.createCollectionViewLayout())
        collectionView.backgroundColor = .systemBackground
        return collectionView
    }()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension UserMediaTimelineViewController {
    static func createCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment -> NSCollectionLayoutSection? in
            switch sectionIndex {
            case MediaSection.main.rawValue:
                let columnCount: CGFloat = round(max(1.0, layoutEnvironment.container.effectiveContentSize.width / 200.0))
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / columnCount),
                                                       heightDimension: .fractionalHeight(1.0)))
                item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .fractionalWidth(1.0 / columnCount)),
                    subitem: item,
                    count: Int(columnCount)
                )
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsetsReference = .readableContent
                return section
            case MediaSection.footer.rawValue:
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .estimated(60)))
                let group = NSCollectionLayoutGroup.horizontal(     // <- horizontal for self size
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(60)),
                    subitem: item,
                    count: 1
                )
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsetsReference = .readableContent
                return section
            default:
                assertionFailure()
                return nil
            }
        }
        return layout
    }
}

extension UserMediaTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        collectionView.delegate = self
        viewModel.setupDiffableDataSource(
            collectionView: collectionView,
            statusMediaGalleryCollectionCellDelegate: self
        )
        
        // setup batch fetch
        viewModel.listBatchFetchViewModel.setup(scrollView: collectionView)
        viewModel.listBatchFetchViewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.stateMachine.enter(UserMediaTimelineViewModel.State.LoadingMore.self)
            }
            .store(in: &disposeBag)
        
        // trigger loading
        viewModel.$userIdentifier
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.stateMachine.enter(UserMediaTimelineViewModel.State.Reloading.self)
            }
            .store(in: &disposeBag)
    }
    
}

// MARK: - UIScrollViewDelegate
extension UserMediaTimelineViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        guard scrollView === collectionView else { return }
//        let cells = collectionView.visibleCells.compactMap { $0 as? ActivityIndicatorCollectionViewCell }
//        guard let loaderCollectionViewCell = cells.first else { return }
//
//        if let tabBar = tabBarController?.tabBar, let window = view.window {
//            let loaderCollectionViewCellFrameInWindow = collectionView.convert(loaderCollectionViewCell.frame, to: nil)
//            let windowHeight = window.frame.height
//            let loaderAppear = (loaderCollectionViewCellFrameInWindow.origin.y + 0.8 * loaderCollectionViewCell.frame.height) < (windowHeight - tabBar.frame.height)
//            if loaderAppear {
//                viewModel.stateMachine.enter(UserMediaTimelineViewModel.State.LoadingMore.self)
//            }
//        } else {
//            viewModel.stateMachine.enter(UserMediaTimelineViewModel.State.LoadingMore.self)
//        }
    }
}

// MARK: - UICollectionViewDelegate
extension UserMediaTimelineViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): did select \(indexPath.debugDescription)")
        guard let cell = collectionView.cellForItem(at: indexPath) as? StatusMediaGalleryCollectionCell else { return }
        Task {
            let source = DataSourceItem.Source(collectionViewCell: nil, indexPath: indexPath)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            await DataSourceFacade.coordinateToMediaPreviewScene(
                provider: self,
                target: .status,
                status: status,
                mediaPreviewContext: DataSourceFacade.MediaPreviewContext(
                    containerView: .mediaView(cell.mediaView),
                    mediaView: cell.mediaView,
                    index: 0        // <-- only one attachment
                )
            )
        }
    }
}

// MARK: - StatusMediaGalleryCollectionCellDelegate
extension UserMediaTimelineViewController: StatusMediaGalleryCollectionCellDelegate {
    func statusMediaGalleryCollectionCell(_ cell: StatusMediaGalleryCollectionCell, coverFlowCollectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Task {
            let source = DataSourceItem.Source(collectionViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            
            guard let cell = coverFlowCollectionView.cellForItem(at: indexPath) as? CoverFlowStackMediaCollectionCell else {
                assertionFailure()
                return
            }
            
            await DataSourceFacade.coordinateToMediaPreviewScene(
                provider: self,
                target: .status,
                status: status,
                mediaPreviewContext: DataSourceFacade.MediaPreviewContext(
                    containerView: .mediaView(cell.mediaView),
                    mediaView: cell.mediaView,
                    index: indexPath.row
                )
            )
        }
    }
    
    func statusMediaGalleryCollectionCell(_ cell: StatusMediaGalleryCollectionCell, toggleContentWarningOverlayViewDisplay contentWarningOverlayView: ContentWarningOverlayView) {
        Task {
            let source = DataSourceItem.Source(collectionViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .status(status) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            
            try await DataSourceFacade.responseToToggleMediaSensitiveAction(
                provider: self,
                target: .status,
                status: status
            )
        }
    }
}

// MARK: - CustomScrollViewContainerController
extension UserMediaTimelineViewController: ScrollViewContainer {
    var scrollView: UIScrollView { return collectionView }
}

// MARK: - TabBarPage
extension UserMediaTimelineViewController: TabBarPage {
    var pageScrollView: UIScrollView {
        collectionView
    }
}

// MARK: - TimelineHeaderCollectionViewCellDelegate
extension UserMediaTimelineViewController: TimelineHeaderCollectionViewCellDelegate { }
