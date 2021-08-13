//
//  StubTimelineViewModel.swift
//  StubTimelineViewModel
//
//  Created by Cirno MainasuK on 2021-8-2.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

@MainActor
final class StubTimelineViewModel {
    
    let logger = Logger(subsystem: "StubTimelineViewModel", category: "Logic")

    // input
    weak var collectionView: UICollectionView?
    
    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<Section, Item>?
    var didLoadLatest = PassthroughSubject<Void, Never>()
}

extension StubTimelineViewModel {
    enum Section: Hashable {
        case main
    }
    
    enum Item: Hashable {
        case stub(id: Int)
    }
    
    func setupDiffableDataSource(collectionView: UICollectionView) {
        self.collectionView = collectionView
        diffableDataSource = StubTimelineViewModel.diffableDataSource(collectionView: collectionView)
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
    }
    
    static func diffableDataSource(
        collectionView: UICollectionView
    ) -> UICollectionViewDiffableDataSource<Section, Item> {
        let stubCellRegistration = UICollectionView.CellRegistration<StubTimelineCollectionViewCell, StubTimelineCollectionViewCell.ViewModel> { cell, indexPath, viewModel in
            cell.primaryLabel.text = viewModel.title
        }
    
        return UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item {
            case .stub(let id):
                let viewModel = StubTimelineCollectionViewCell.ViewModel(title: "\(id)")
                return collectionView.dequeueConfiguredReusableCell(using: stubCellRegistration, for: indexPath, item: viewModel)
            }
        }
    }
    
    struct Difference<T> {
        let item: T
        let sourceIndexPath: IndexPath
        let sourceDistanceToTop: CGFloat
        let targetIndexPath: IndexPath
    }
    
    private func calculateReloadSnapshotDifference<S: Hashable, T: Hashable>(
        collectionView: UICollectionView,
        oldSnapshot: NSDiffableDataSourceSnapshot<S, T>,
        newSnapshot: NSDiffableDataSourceSnapshot<S, T>
    ) -> Difference<T>? {
        guard let sourceIndexPath = collectionView.indexPathsForVisibleItems.sorted().first else { return nil }
        guard let layoutAttributes = collectionView.layoutAttributesForItem(at: sourceIndexPath) else { return nil }
        
        let sourceDistanceToTop = layoutAttributes.frame.origin.y - collectionView.bounds.origin.y
        
        guard sourceIndexPath.section < oldSnapshot.numberOfSections,
              sourceIndexPath.row < oldSnapshot.numberOfItems(inSection: oldSnapshot.sectionIdentifiers[sourceIndexPath.section])
        else { return nil }
        
        let sectionIdentifier = oldSnapshot.sectionIdentifiers[sourceIndexPath.section]
        let item = oldSnapshot.itemIdentifiers(inSection: sectionIdentifier)[sourceIndexPath.row]
        
        guard let targetIndexPathRow = newSnapshot.indexOfItem(item),
              let newSectionIdentifier = newSnapshot.sectionIdentifier(containingItem: item),
              let targetIndexPathSection = newSnapshot.indexOfSection(newSectionIdentifier)
        else { return nil }
        
        let targetIndexPath = IndexPath(row: targetIndexPathRow, section: targetIndexPathSection)
        
        return Difference(
            item: item,
            sourceIndexPath: sourceIndexPath,
            sourceDistanceToTop: sourceDistanceToTop,
            targetIndexPath: targetIndexPath
        )
    }
    
    func loadLatest() async {
        guard let collectionView = self.collectionView else { return }
        guard let diffableDataSource = self.diffableDataSource else { return }
        let oldSnapshot = diffableDataSource.snapshot()
        let count = oldSnapshot.numberOfItems
        let start = count + 1
        
        var items: [Item] = oldSnapshot.itemIdentifiers
        let newItems = (start..<start+20).map { index in Item.stub(id: index) }
        items.insert(contentsOf: newItems.reversed(), at: 0)
        
        let newSnapshot: NSDiffableDataSourceSnapshot<Section, Item> = {
            var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
            snapshot.appendSections([.main])
            snapshot.appendItems(items, toSection: .main)
            return snapshot
        }()
    
        await Task.sleep(2_000_000_000) // 2s
        
        let difference = calculateReloadSnapshotDifference(collectionView: collectionView, oldSnapshot: oldSnapshot, newSnapshot: newSnapshot)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let animatingDifferences = difference == nil
            diffableDataSource.apply(newSnapshot, animatingDifferences: animatingDifferences) {
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot")
                defer {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) { [weak self] in
                        self?.didLoadLatest.send()
                    }
                }
                guard let difference = difference else { return }
                guard let layoutAttributes = collectionView.layoutAttributesForItem(at: difference.targetIndexPath) else { return }
                let targetDistanceToTop = layoutAttributes.frame.origin.y - collectionView.bounds.origin.y
                let offset = targetDistanceToTop - difference.sourceDistanceToTop
                var contentOffset = collectionView.contentOffset
                contentOffset.y += offset
                collectionView.setContentOffset(contentOffset, animated: false)
            }
        }
    }

}
