//
//  ListTimelineViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack

public protocol DifferenceItem {
    var isTransient: Bool { get }
}

extension ListTimelineViewModel {
    
    struct Difference<T>: CustomStringConvertible {
        let item: T
        let sourceIndexPath: IndexPath
        let sourceDistanceToTableViewTopEdge: CGFloat
        let targetIndexPath: IndexPath
        
        var description: String {
            """
            source: \(sourceIndexPath.debugDescription)
            target: \(targetIndexPath.debugDescription)
            offset: \(sourceDistanceToTableViewTopEdge)
            item: \(String(describing: item))
            """
        }
    }
    
    @MainActor func calculateReloadSnapshotDifference<S: Hashable, T: Hashable & DifferenceItem>(
        tableView: UITableView,
        oldSnapshot: NSDiffableDataSourceSnapshot<S, T>,
        newSnapshot: NSDiffableDataSourceSnapshot<S, T>
    ) -> Difference<T>? {
        guard oldSnapshot.numberOfItems != 0 else { return nil }
        guard let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows?.sorted() else { return nil }

        // find index of the first visible item in both old and new snapshot
        var _index: Int?
        let items = oldSnapshot.itemIdentifiers
        for (i, item) in items.enumerated() {
            guard let _ = indexPathsForVisibleRows.first(where: { $0.row == i }) else { continue }
            guard !item.isTransient else { continue }
            guard newSnapshot.indexOfItem(item) != nil else { continue }
            _index = i
            break
        }

        guard let index = _index else { return nil }
        let sourceIndexPath = IndexPath(row: index, section: 0)

        let rectForSourceItemCell = tableView.rectForRow(at: sourceIndexPath)
        let sourceDistanceToTableViewTopEdge: CGFloat = {
            if tableView.window != nil {
                return tableView.convert(rectForSourceItemCell, to: nil).origin.y - tableView.safeAreaInsets.top
            } else {
                return rectForSourceItemCell.origin.y - tableView.contentOffset.y - tableView.safeAreaInsets.top
            }
        }()
        
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
            sourceDistanceToTableViewTopEdge: sourceDistanceToTableViewTopEdge,
            targetIndexPath: targetIndexPath
        )
    }
    
    @MainActor func reloadSnapshotWithDifference(
        tableView: UITableView,
        snapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>,
        difference: Difference<StatusItem>
    ) {
        tableView.isUserInteractionEnabled = false
        tableView.panGestureRecognizer.isEnabled = false
        defer {
            tableView.isUserInteractionEnabled = true
            tableView.panGestureRecognizer.isEnabled = true
        }
        diffableDataSource?.applySnapshotUsingReloadData(snapshot)
        tableView.scrollToRow(at: difference.targetIndexPath, at: .top, animated: false)
        var contentOffset = tableView.contentOffset
        contentOffset.y = tableView.contentOffset.y - difference.sourceDistanceToTableViewTopEdge
        tableView.setContentOffset(contentOffset, animated: false)
    }
    
}
