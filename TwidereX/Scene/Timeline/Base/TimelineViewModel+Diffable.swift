//
//  TimelineViewModel+Diffable.swift
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

extension TimelineViewModel {
    
    @MainActor func updateDataSource(
        snapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>,
        animatingDifferences: Bool
    ) async {
        await self.diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    @MainActor func updateSnapshotUsingReloadData(
        snapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>
    ) async {
        await self.diffableDataSource?.applySnapshotUsingReloadData(snapshot)
    }
    
}

extension TimelineViewModel {
    struct Difference<T> {
        let item: T
        let sourceIndexPath: IndexPath
        let sourceDistanceToTableViewTopEdge: CGFloat
        let targetIndexPath: IndexPath
    }
    
    @MainActor func calculateReloadSnapshotDifference<S: Hashable, T: Hashable>(
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

extension TimelineViewModel {

    // load lastest
    func loadLatest() async {
        isLoadingLatest = true
        defer {
            isLoadingLatest = false
        }
        guard let authenticationContext = context.authenticationService.activeAuthenticationContext.value else { return }
        do {
            switch authenticationContext {
            case .twitter(let authenticationContext):
                _ = try await context.apiService.twitterHomeTimeline(
                    maxID: nil,
                    authenticationContext: authenticationContext
                )
            case .mastodon(let authenticationContext):
                switch kind {
                case .home:
                    _ =  try await context.apiService.mastodonHomeTimeline(
                        maxID: nil,
                        authenticationContext: authenticationContext
                    )
                case .federated(let local):
                    let response = try await context.apiService.mastodonPublicTimeline(
                        local: local,
                        maxID: nil,
                        authenticationContext: authenticationContext
                    )
                    let statusIDs = response.value.map { $0.id }
                    statusRecordFetchedResultController.mastodonStatusFetchedResultController.prepend(statusIDs: statusIDs)
                }
            }
        } catch {
            self.didLoadLatest.send()
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(error.localizedDescription)")
        }
    }
    
    // load timeline gap
    func loadMore(item: StatusItem) async {
        guard case let .feedLoader(record) = item else { return }
        guard let authenticationContext = context.authenticationService.activeAuthenticationContext.value else { return }
        guard let diffableDataSource = diffableDataSource else { return }
        var snapshot = diffableDataSource.snapshot()

        let managedObjectContext = context.managedObjectContext
        let key = "LoadMore@\(record.objectID)"
        
        guard let feed = record.object(in: managedObjectContext) else { return }
        // keep transient property live
        managedObjectContext.cache(feed, key: key)
        defer {
            managedObjectContext.cache(nil, key: key)
        }
        do {
            // update state
            try await managedObjectContext.performChanges {
                feed.update(isLoadingMore: true)
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
        
        // reconfigure item
        snapshot.reconfigureItems([item])
        await updateDataSource(snapshot: snapshot, animatingDifferences: true)
        
        // fetch data
        do {
            switch (feed.content, authenticationContext) {
            case (.twitter(let status), .twitter(let authenticationContext)):
                _ = try await context.apiService.twitterHomeTimeline(
                    maxID: status.id,
                    authenticationContext: authenticationContext
                )
            case (.mastodon(let status), .mastodon(let authenticationContext)):
                switch kind {
                case .home:
                    _ = try await context.apiService.mastodonHomeTimeline(
                        maxID: status.id,
                        authenticationContext: authenticationContext
                    )
                case .federated:
                    assertionFailure()
                }
            default:
                assertionFailure()
            }
        } catch {
            do {
                // restore state
                try await managedObjectContext.performChanges {
                    feed.update(isLoadingMore: false)
                }
            } catch {
                assertionFailure(error.localizedDescription)
            }
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch more failure: \(error.localizedDescription)")
        }
        
        // reconfigure item again
        snapshot.reconfigureItems([item])
        await updateDataSource(snapshot: snapshot, animatingDifferences: true)
    }
    
}
