//
//  GridTimelineViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-13.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TabBarPager

class GridTimelineViewController: TimelineViewController {
    
    var viewModel: GridTimelineViewModel! {
        get {
            return _viewModel as? GridTimelineViewModel
        }
        set {
            _viewModel = newValue
        }
    }
        
    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: GridTimelineViewController.createCollectionViewLayout())
        collectionView.backgroundColor = .systemBackground
        return collectionView
    }()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension GridTimelineViewController {
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

extension GridTimelineViewController {
    
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
        
        // setup refresh control
        viewModel.$isRefreshControlEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRefreshControlEnabled in
                guard let self = self else { return }
                self.collectionView.refreshControl = isRefreshControlEnabled ? self.refreshControl : nil
            }
            .store(in: &disposeBag)

        // setup batch fetch
        viewModel.listBatchFetchViewModel.setup(scrollView: collectionView)
        viewModel.listBatchFetchViewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.stateMachine.enter(GridTimelineViewModel.LoadOldestState.Loading.self)
            }
            .store(in: &disposeBag)
    }
    
}

extension GridTimelineViewController {
    
    public func reload() {
        Task {
            self.viewModel.stateMachine.enter(ListTimelineViewModel.LoadOldestState.Reloading.self)
        }   // end Task
    }
    
}

// MARK: - UICollectionViewDelegate
extension GridTimelineViewController: UICollectionViewDelegate {

}

// MARK: - StatusMediaGalleryCollectionCellDelegate
extension GridTimelineViewController: StatusMediaGalleryCollectionCellDelegate {
    func statusMediaGalleryCollectionCell(_ cell: StatusMediaGalleryCollectionCell, mediaStackContainerViewModel: TwidereUI.MediaStackContainerView.ViewModel, didSelectMediaView mediaViewModel: TwidereUI.MediaView.ViewModel) {
        Task {
            let source = DataSourceItem.Source(collectionViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard let status = await item.status(in: self.context.managedObjectContext) else {
                assertionFailure("only works for status data provider")
                return
            }
            await DataSourceFacade.coordinateToStatusThreadScene(
                provider: self,
                kind: .status(status)
            )
        }   // end Task
    }
}

// MARK: - CustomScrollViewContainerController
extension GridTimelineViewController: ScrollViewContainer {
    var scrollView: UIScrollView { return collectionView }
}

// MARK: - TabBarPage
extension GridTimelineViewController: TabBarPage {
    var pageScrollView: UIScrollView {
        collectionView
    }
}

// MARK: - TimelineHeaderCollectionViewCellDelegate
extension GridTimelineViewController: TimelineHeaderCollectionViewCellDelegate { }
