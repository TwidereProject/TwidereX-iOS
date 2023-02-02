//
//  ListTimelineViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-14.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import TwidereCore

class ListTimelineViewModel: TimelineViewModel {
    
    // input
    @Published var scrollPositionRecord: ScrollPositionRecord? = nil
    
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, StatusItem>?
    
    @MainActor
    override func updateDataSource(
        snapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>,
        animatingDifferences: Bool
    ) {
        diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
        
        if enableAutoFetchLatest, !didAutoFetchLatest {
            autoFetchLatestAction.send()
        }
    }
    
    @MainActor
    override func updateSnapshotUsingReloadData(
        snapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>
    ) {
        diffableDataSource?.applySnapshotUsingReloadData(snapshot)
        
        if enableAutoFetchLatest, !didAutoFetchLatest {
            autoFetchLatestAction.send()
        }
    }
    
}

extension ListTimelineViewModel {
    
    @MainActor
    func loadMore(item: StatusItem) async {
        guard case let .feedLoader(record) = item else { return }
        guard let diffableDataSource = diffableDataSource else { return }
        var snapshot = diffableDataSource.snapshot()

        let authenticationContext = authContext.authenticationContext

        let managedObjectContext = context.managedObjectContext
        let key = "LoadMore@\(record.objectID)#\(UUID().uuidString)"

        guard let feed = record.object(in: managedObjectContext) else { return }
        guard let statusObject = feed.statusObject else { return }
        
        // keep transient property alive
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
        updateDataSource(snapshot: snapshot, animatingDifferences: true)

        // fetch data
        do {
            let fetchContext = StatusFetchViewModel.Timeline.FetchContext(
                managedObjectContext: managedObjectContext,
                authenticationContext: authenticationContext,
                kind: kind,
                position: .middle(anchor: statusObject.asRecord),
                filter: StatusFetchViewModel.Timeline.Filter(rule: .empty)
            )
            let input = try await StatusFetchViewModel.Timeline.prepare(fetchContext: fetchContext)
            let _ = try await StatusFetchViewModel.Timeline.fetch(
                api: context.apiService,
                input: input
            )
            switch kind {
            case .home:
                break
            default:
                assertionFailure("only home timeline has gap")
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
        updateDataSource(snapshot: snapshot, animatingDifferences: true)
    }
    
}

extension ListTimelineViewModel {
    struct ScrollPositionRecord {
        let item: StatusItem
        let offset: CGFloat
        let timestamp: Date
    }
}
