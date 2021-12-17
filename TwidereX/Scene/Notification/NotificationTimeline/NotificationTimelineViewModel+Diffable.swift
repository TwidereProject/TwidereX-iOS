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
import MastodonSDK

extension NotificationTimelineViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView,
        statusViewTableViewCellDelegate: StatusViewTableViewCellDelegate,
        userTableViewCellDelegate: UserTableViewCellDelegate
    ) {
        let configuration = NotificationSection.Configuration(
            statusViewTableViewCellDelegate: statusViewTableViewCellDelegate,
            userTableViewCellDelegate: userTableViewCellDelegate
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
                                newSnapshot.insertItems([.feedLoader(record: record)], afterItem: item)
                            }
                        }
                    }

                    let hasChanges = newSnapshot.itemIdentifiers != oldSnapshot.itemIdentifiers
                    guard hasChanges else {
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): snapshot not changes")
                        self.didLoadLatest.send()
                        return
                    }
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): snapshot has changes")

                    await self.updateDataSource(snapshot: newSnapshot, animatingDifferences: false)
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
                _ = try await context.apiService.mastodonNotificationTimeline(
                    query: Mastodon.API.Notification.NotificationsQuery(
                        maxID: nil,
                        excludeTypes: {
                            switch scope {
                            case .all:
                                return nil
                            case .mentions:
                                return [.follow, .followRequest, .reblog, .favourite, .poll]
                            }
                        }()
                    ),
                    authenticationContext: authenticationContext
                )
            }
        } catch {
            self.didLoadLatest.send()
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(error.localizedDescription)")
        }
    }
    
    // load timeline gap
    func loadMore(item: NotificationItem) async {
        guard case let .feedLoader(record) = item else { return }
        guard let authenticationContext = context.authenticationService.activeAuthenticationContext.value else { return }

        let managedObjectContext = context.managedObjectContext
        let key = "LoadMore@\(record.objectID)"
        
        // return when already loading state
        guard managedObjectContext.cache(froKey: key) == nil else { return }

        guard let feed = record.object(in: managedObjectContext) else { return }
        // keep transient property live
        managedObjectContext.cache(feed, key: key)
        defer {
            managedObjectContext.cache(nil, key: key)
        }
        
        // fetch data
        do {
            switch (feed.content, authenticationContext) {
            case (.twitter(let status), .twitter(let authenticationContext)):
                let query = Twitter.API.Statuses.Timeline.TimelineQuery(
                    count: 20,
                    maxID: status.id
                )
                _ = try await context.apiService.twitterMentionTimeline(
                    query: query,
                    authenticationContext: authenticationContext
                )
                
            case (.mastodonNotification(let mastodonNotification), .mastodon(let authenticationContext)):
                _ = try await context.apiService.mastodonNotificationTimeline(
                    query: Mastodon.API.Notification.NotificationsQuery(
                        maxID: mastodonNotification.id,
                        excludeTypes: {
                            switch scope {
                            case .all:
                                return nil
                            case .mentions:
                                return [.follow, .followRequest, .reblog, .favourite, .poll]
                            }
                        }()
                    ),
                    authenticationContext: authenticationContext
                )
            default:
                assertionFailure()
            }
        } catch {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch more failure: \(error.localizedDescription)")
        }
    }
    
}
