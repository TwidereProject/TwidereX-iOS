//
//  NotificationTimelineViewModel+Diffable.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import CoreData
import CoreDataStack
import TwitterSDK

extension NotificationTimelineViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView,
        statusViewTableViewCellDelegate: StatusViewTableViewCellDelegate
    ) {
        let configuration = NotificationSection.Configuration(
            statusViewTableViewCellDelegate: statusViewTableViewCellDelegate
        )
        diffableDataSource = NotificationSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: configuration
        )

        var snapshot = NSDiffableDataSourceSnapshot<NotificationSection, NotificationItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
        
        fetchedResultsController.records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): incoming \(records.count) objects")
                Task {
                    let start = CACurrentMediaTime()
                    defer {
                        let end = CACurrentMediaTime()
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): cost \(end - start, format: .fixed(precision: 4 ))s to process \(records.count) feeds")
                    }
                    let oldSnapshot = diffableDataSource.snapshot()
                    var newSnapshot: NSDiffableDataSourceSnapshot<NotificationSection, NotificationItem> = {
                        let newItems = records.map { record in
                            NotificationItem.feed(record: record)
                        }
                        var snapshot = NSDiffableDataSourceSnapshot<NotificationSection, NotificationItem>()
                        snapshot.appendSections([.main])
                        snapshot.appendItems(newItems, toSection: .main)
                        return snapshot
                    }()

                    let parentManagedObjectContext = self.context.managedObjectContext
                    let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                    managedObjectContext.parent = parentManagedObjectContext
                    await managedObjectContext.perform {
                        let anchors: [Feed] = {
                            let request = Feed.sortedFetchRequest
                            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                                Feed.hasMorePredicate(),
                                self.fetchedResultsController.predicate.value,
                            ])
                            do {
                                return try managedObjectContext.fetch(request)
                            } catch {
                                assertionFailure(error.localizedDescription)
                                return []
                            }
                        }()

                        let itemIdentifiers = newSnapshot.itemIdentifiers
                        for (index, item) in itemIdentifiers.enumerated() {
                            guard case let .feed(record) = item else { continue }
                            guard anchors.contains(where: { feed in feed.objectID == record.objectID }) else { continue }
                            let isLast = index + 1 == itemIdentifiers.count
                            if isLast {
                                newSnapshot.insertItems([.bottomLoader], afterItem: item)
                            } else {
                                // TODO:
                                // newSnapshot.insertItems([.feedLoader(record: record)], afterItem: item)
                            }
                        }
                    }

                    let hasChanges = newSnapshot.itemIdentifiers != oldSnapshot.itemIdentifiers
                    if !hasChanges {
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): snapshot not changes")
                        self.didLoadLatest.send()
                        return
                    } else {
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): snapshot has changes")
                    }

                    guard let difference = await self.calculateReloadSnapshotDifference(
                        tableView: tableView,
                        oldSnapshot: oldSnapshot,
                        newSnapshot: newSnapshot
                    ) else {
                        await self.updateDataSource(snapshot: newSnapshot, animatingDifferences: false)
                        self.didLoadLatest.send()
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot")
                        return
                    }
                    
                    await self.updateSnapshotUsingReloadData(snapshot: newSnapshot)
                    await tableView.scrollToRow(at: difference.targetIndexPath, at: .top, animated: false)
                    var contentOffset = await tableView.contentOffset
                    contentOffset.y = await tableView.contentOffset.y - difference.sourceDistanceToTableViewTopEdge
                    await tableView.setContentOffset(contentOffset, animated: false)
                    self.didLoadLatest.send()
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot")
                }   // end Task
            }
            .store(in: &disposeBag)
    }
    
    @MainActor private func updateDataSource(
        snapshot: NSDiffableDataSourceSnapshot<NotificationSection, NotificationItem>,
        animatingDifferences: Bool
    ) async {
        await self.diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    @MainActor private func updateSnapshotUsingReloadData(
        snapshot: NSDiffableDataSourceSnapshot<NotificationSection, NotificationItem>
    ) async {
        await self.diffableDataSource?.applySnapshotUsingReloadData(snapshot)
    }
    
}

extension NotificationTimelineViewModel {
    struct Difference<T> {
        let item: T
        let sourceIndexPath: IndexPath
        let sourceDistanceToTableViewTopEdge: CGFloat
        let targetIndexPath: IndexPath
    }
    
    @MainActor private func calculateReloadSnapshotDifference<S: Hashable, T: Hashable>(
        tableView: UITableView,
        oldSnapshot: NSDiffableDataSourceSnapshot<S, T>,
        newSnapshot: NSDiffableDataSourceSnapshot<S, T>
    ) -> Difference<T>? {
        guard let sourceIndexPath = (tableView.indexPathsForVisibleRows ?? []).sorted().first else { return nil }
        let rectForSourceItemCell = tableView.rectForRow(at: sourceIndexPath)
        let sourceDistanceToTableViewTopEdge = tableView.convert(rectForSourceItemCell, to: nil).origin.y - tableView.safeAreaInsets.top
        
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
            sourceDistanceToTableViewTopEdge: sourceDistanceToTableViewTopEdge,
            targetIndexPath: targetIndexPath
        )
    }
}

extension NotificationTimelineViewModel {

    // load lastest
    func loadLatest() async {
        guard let authenticationContext = context.authenticationService.activeAuthenticationContext.value else { return }
        do {
            switch authenticationContext {
            case .twitter(let authenticationContext):
                _ = try await context.apiService.twitterMentionTimeline(
                    query: Twitter.API.Statuses.Timeline.TimelineQuery(
                        maxID: nil
                    ),
                    authenticationContext: authenticationContext
                )
            case .mastodon(let authenticationContext):
                _ =  try await context.apiService.mastodonHomeTimeline(
                    maxID: nil,
                    authenticationContext: authenticationContext
                )
            }
        } catch {
            self.didLoadLatest.send()
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(error.localizedDescription)")
        }
    }
    
}
