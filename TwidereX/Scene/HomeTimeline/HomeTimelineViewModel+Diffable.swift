//
//  HomeTimelineViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import CoreData
import CoreDataStack

extension HomeTimelineViewModel {
    
    func setupDiffableDataSource(
        collectionView: UICollectionView
    ) {
        
        diffableDataSource = StatusSection.diffableDataSource(
            collectionView: collectionView,
            context: context
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
        
        fetchedResultsController.objectIDs.removeDuplicates()
            .receive(on: DispatchQueue.main, options: nil)
            .sink { [weak self] objectIDs in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                
                let oldSnapshot = diffableDataSource.snapshot()

                let newSnapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem> = {
                    let newItems = objectIDs.map { StatusItem.homeTimelineFeed(objectID: $0) }
                    var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
                    snapshot.appendSections([.main])
                    snapshot.appendItems(newItems, toSection: .main)
                    return snapshot
                }()

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    let difference = self.calculateReloadSnapshotDifference(
                        collectionView: collectionView,
                        oldSnapshot: oldSnapshot,
                        newSnapshot: newSnapshot
                    )
                    
                    let animatingDifferences = difference == nil
                    diffableDataSource.apply(newSnapshot, animatingDifferences: animatingDifferences) {
                        defer {
                            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot")
                            self.didLoadLatest.send()
                        }
                        guard let difference = difference else { return }
//                        collectionView.scrollToItem(at: difference.targetIndexPath, at: .top, animated: false)
//                        let targetDistanceToTop = collectionView.contentOffset.y
//                        let offset = targetDistanceToTop - difference.sourceDistanceToTop
//                        collectionView.contentOffset.y = collectionView.contentOffset.y + offset
                        guard let layoutAttributes = collectionView.layoutAttributesForItem(at: difference.targetIndexPath) else { return }
                        let targetDistanceToTop = layoutAttributes.frame.origin.y - collectionView.bounds.origin.y
                        let offset = targetDistanceToTop - difference.sourceDistanceToTop
                        collectionView.contentOffset.y = collectionView.contentOffset.y + offset
                    }
                }
            }
            .store(in: &disposeBag)
    }
    
}

extension HomeTimelineViewModel {
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
}

extension HomeTimelineViewModel {

    func loadLatest() async {
        guard let authenticationContext = context.authenticationService.activeTwitterAuthenticationContext.value else { return }
        do {
            let response = try await context.apiService.twitterHomeTimeline(
                maxID: nil,
                authenticationContext: authenticationContext
            )
            // FIXME: needs stop when no new status
            // self.didLoadLatest.send()
            
        } catch {
            self.didLoadLatest.send()
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(error.localizedDescription)")
        }
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
//extension HomeTimelineViewModel: NSFetchedResultsControllerDelegate {
//
//    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//    }
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
//        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//
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
//            let timelineIndexes: [TimelineIndex] = {
//                let request = TimelineIndex.sortedFetchRequest
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
//            // that's will be the most fastest fetch because of upstream just update and no modify needs consider
//            let endFetch = CACurrentMediaTime()
//            os_log("%{public}s[%{public}ld], %{public}s: fetch timelineIndexes cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, endFetch - start)
//
//            var oldSnapshotAttributeDict: [NSManagedObjectID : Item.Attribute] = [:]
//
//            for item in oldSnapshot.itemIdentifiers {
//                guard case let .homeTimelineIndex(objectID, attribute) = item else { continue }
//                oldSnapshotAttributeDict[objectID] = attribute
//            }
//            let endPrepareCache = CACurrentMediaTime()
//
//            var newTimelineItems: [Item] = []
//            os_log("%{public}s[%{public}ld], %{public}s: prepare timelineIndex cache cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, endPrepareCache - endFetch)
//            for (i, timelineIndex) in timelineIndexes.enumerated() {
//                let attribute = oldSnapshotAttributeDict[timelineIndex.objectID] ?? Item.Attribute()
//
//                // append new item into snapshot
//                newTimelineItems.append(.homeTimelineIndex(objectID: timelineIndex.objectID, attribute: attribute))
//
//                let isLast = i == timelineIndexes.count - 1
//                switch (isLast, timelineIndex.hasMore) {
//                case (true, false):
//                    attribute.separatorLineStyle = .normal
//                case (false, true):
//                    attribute.separatorLineStyle = .expand
//                    newTimelineItems.append(.middleLoader(upperTimelineIndexAnchorObjectID: timelineIndex.objectID))
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
//            os_log("%{public}s[%{public}ld], %{public}s: calculate home timeline snapshot with %ld items cost %.2fs. avg %.5fs per item", ((#file as NSString).lastPathComponent), #line, #function, newSnapshot.itemIdentifiers.count, endSnapshot - endPrepareCache, (endSnapshot - endPrepareCache) / Double(count))
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
//    }
//
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
//}
