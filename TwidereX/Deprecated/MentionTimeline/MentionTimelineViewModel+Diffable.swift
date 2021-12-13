//
//  MentionTimelineViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-3.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import CoreData
import CoreDataStack
import GameplayKit

extension MentionTimelineViewModel {
    
    func setupDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency,
        timelinePostTableViewCellDelegate: TimelinePostTableViewCellDelegate,
        timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate
    ) {
        let timestampUpdatePublisher = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .share()
            .eraseToAnyPublisher()
        
        diffableDataSource = TimelineSection.tableViewDiffableDataSource(
            for: tableView,
            dependency: dependency,
            managedObjectContext: fetchedResultsController.managedObjectContext,
            timestampUpdatePublisher: timestampUpdatePublisher,
            timelinePostTableViewCellDelegate: timelinePostTableViewCellDelegate,
            timelineMiddleLoaderTableViewCellDelegate: timelineMiddleLoaderTableViewCellDelegate,
            timelineHeaderTableViewCellDelegate: nil
        )
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension MentionTimelineViewModel: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

//        guard let tableView = self.tableView else { return }
//        guard let navigationBar = self.contentOffsetAdjustableTimelineViewControllerDelegate?.navigationBar() else { return }
//
//        guard let diffableDataSource = self.diffableDataSource else { return }
//        let oldSnapshot = diffableDataSource.snapshot()
//
//        let predicate = fetchedResultsController.fetchRequest.predicate
//        let parentManagedObjectContext = fetchedResultsController.managedObjectContext
//        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
//        managedObjectContext.parent = parentManagedObjectContext
//
//        managedObjectContext.perform {
//            let start = CACurrentMediaTime()
//            var shouldAddBottomLoader = false
//
//            let mentionTimelineIndexes: [MentionTimelineIndex] = {
//                let request = MentionTimelineIndex.sortedFetchRequest
//                request.returnsObjectsAsFaults = false
//                request.predicate = predicate
//                do {
//                    return try managedObjectContext.fetch(request)
//                } catch {
//                    assertionFailure(error.localizedDescription)
//                    return []
//                }
//            }()
//
//            let endFetch = CACurrentMediaTime()
//            os_log("%{public}s[%{public}ld], %{public}s: fetch mentionTimelineIndexes cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, endFetch - start)
//
//            var oldSnapshotAttributeDict: [NSManagedObjectID : Item.Attribute] = [:]
//            for item in oldSnapshot.itemIdentifiers {
//                guard case let .mentionTimelineIndex(objectID, attribute) = item else { continue }
//                oldSnapshotAttributeDict[objectID] = attribute
//            }
//            let endPrepareCache = CACurrentMediaTime()
//
//            var newTimelineItems: [Item] = []
//
//            os_log("%{public}s[%{public}ld], %{public}s: prepare timelineIndex cache cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, endPrepareCache - endFetch)
//            for (i, mentionTimelineIndex) in mentionTimelineIndexes.enumerated() {
//                let attribute = oldSnapshotAttributeDict[mentionTimelineIndex.objectID] ?? Item.Attribute()
//
//                // append new item into snapshot
//                newTimelineItems.append(.mentionTimelineIndex(objectID: mentionTimelineIndex.objectID, attribute: attribute))
//
//                let isLast = i == mentionTimelineIndexes.count - 1
//                switch (isLast, mentionTimelineIndex.hasMore) {
//                case (true, false):
//                    attribute.separatorLineStyle = .normal
//                case (false, true):
//                    attribute.separatorLineStyle = .expand
//                    newTimelineItems.append(.middleLoader(upperTimelineIndexAnchorObjectID: mentionTimelineIndex.objectID))
//                case (true, true):
//                    attribute.separatorLineStyle = .normal
//                    shouldAddBottomLoader = true
//                case (false, false):
//                    attribute.separatorLineStyle = .indent
//                }
//            }   // end for
//
//            var newSnapshot = NSDiffableDataSourceSnapshot<TimelineSection, Item>()
//            newSnapshot.appendSections([.main])
//            newSnapshot.appendItems(newTimelineItems, toSection: .main)
//
//            let endSnapshot = CACurrentMediaTime()
//            let count = max(1, newSnapshot.itemIdentifiers.count)
//            os_log("%{public}s[%{public}ld], %{public}s: calculate mention timeline snapshot with %ld items cost %.2fs. avg %.5fs per item", ((#file as NSString).lastPathComponent), #line, #function, newSnapshot.itemIdentifiers.count, endSnapshot - endPrepareCache, (endSnapshot - endPrepareCache) / Double(count))
//
//            DispatchQueue.main.async {
//                if shouldAddBottomLoader, !(self.loadoldestStateMachine.currentState is LoadOldestState.NoMore) {
//                    newSnapshot.appendItems([.bottomLoader], toSection: .main)
//                }
//
//                guard let difference = self.calculateReloadSnapshotDifference(navigationBar: navigationBar, tableView: tableView, oldSnapshot: oldSnapshot, newSnapshot: newSnapshot) else {
//                    diffableDataSource.apply(newSnapshot)
//                    self.isFetchingLatestTimeline.value = false
//                    return
//                }
//
//                diffableDataSource.apply(newSnapshot, animatingDifferences: false) {
//                    tableView.scrollToRow(at: difference.targetIndexPath, at: .top, animated: false)
//                    tableView.contentOffset.y = tableView.contentOffset.y - difference.offset
//                    self.isFetchingLatestTimeline.value = false
//                }
//
//                let end = CACurrentMediaTime()
//                os_log("%{public}s[%{public}ld], %{public}s: calculate home timeline layout cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - endSnapshot)
//            }
//        }   // end perform
    }
    
//    private struct Difference<T> {
//        let item: T
//        let sourceIndexPath: IndexPath
//        let targetIndexPath: IndexPath
//        let offset: CGFloat
//    }
//    
//    private func calculateReloadSnapshotDifference<T: Hashable>(
//        navigationBar: UINavigationBar,
//        tableView: UITableView,
//        oldSnapshot: NSDiffableDataSourceSnapshot<TimelineSection, T>,
//        newSnapshot: NSDiffableDataSourceSnapshot<TimelineSection, T>
//    ) -> Difference<T>? {
//        guard oldSnapshot.numberOfItems != 0 else { return nil }
//        
//        // old snapshot not empty. set source index path to first item if not match
//        let sourceIndexPath = UIViewController.topVisibleTableViewCellIndexPath(in: tableView, navigationBar: navigationBar) ?? IndexPath(row: 0, section: 0)
//        
//        guard sourceIndexPath.row < oldSnapshot.itemIdentifiers(inSection: .main).count else { return nil }
//        
//        let timelineItem = oldSnapshot.itemIdentifiers(inSection: .main)[sourceIndexPath.row]
//        guard let itemIndex = newSnapshot.itemIdentifiers(inSection: .main).firstIndex(of: timelineItem) else { return nil }
//        let targetIndexPath = IndexPath(row: itemIndex, section: 0)
//        
//        let offset = UIViewController.tableViewCellOriginOffsetToWindowTop(in: tableView, at: sourceIndexPath, navigationBar: navigationBar)
//        return Difference(
//            item: timelineItem,
//            sourceIndexPath: sourceIndexPath,
//            targetIndexPath: targetIndexPath,
//            offset: offset
//        )
//    }
//    
}
