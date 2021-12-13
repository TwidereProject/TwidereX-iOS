//
//  SearchMediaViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-29.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack

final class SearchMediaViewController: UIViewController, NeedsDependency, MediaPreviewTransitionHostViewController {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    let logger = Logger(subsystem: "SearchMediaViewController", category: "ViewController")
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: SearchMediaViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()

    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UserMediaTimelineViewController.createCollectionViewLayout())
        collectionView.backgroundColor = .systemBackground
        return collectionView
    }()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
}

extension SearchMediaViewController {

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
                guard self.isDisplaying else { return }
                guard !self.viewModel.searchText.isEmpty else { return }
                self.viewModel.stateMachine.enter(SearchMediaViewModel.State.Loading.self)
            }
            .store(in: &disposeBag)
        
        KeyboardResponderService
            .configure(
                scrollView: collectionView,
                layoutNeedsUpdate: viewModel.viewDidAppear.eraseToAnyPublisher()
            )
            .store(in: &disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
}

extension SearchMediaViewController {
    
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
                if #available(iOS 14.0, *) {
                    section.contentInsetsReference = .readableContent
                } else {
                    // Fallback on earlier versions
                    // iOS 13 workaround
                    section.contentInsets.leading = 16
                    section.contentInsets.trailing = 16
                }
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
                if #available(iOS 14.0, *) {
                    section.contentInsetsReference = .readableContent
                } else {
                    // Fallback on earlier versions
                }
                return section
            default:
                assertionFailure()
                return nil
            }
        }
        return layout
    }
    
}

// MARK: - UICollectionViewDelegate
extension SearchMediaViewController: UICollectionViewDelegate {
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
extension SearchMediaViewController: StatusMediaGalleryCollectionCellDelegate {
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
}
