//
//  UserTimelineViewModel+Diffable.swift
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
import TwidereCore
import AppShared

extension UserTimelineViewModel {
    
    @MainActor
    func setupDiffableDataSource(
        tableView: UITableView,
        statusViewTableViewCellDelegate: StatusViewTableViewCellDelegate
    ) {
        let configuration = StatusSection.Configuration(
            statusViewTableViewCellDelegate: statusViewTableViewCellDelegate,
            timelineMiddleLoaderTableViewCellDelegate: nil,
            statusViewConfigurationContext: StatusView.ConfigurationContext(
                authContext: authContext,
                dateTimeProvider: DateTimeSwiftProvider(),
                twitterTextProvider: OfficialTwitterTextProvider(),
                viewLayoutFramePublisher: $viewLayoutFrame
            )
        )
        diffableDataSource = StatusSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: configuration
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.applySnapshotUsingReloadData(snapshot)
        
        statusRecordFetchedResultController.$records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): incoming \(records.count) objects")
                Task { @MainActor in
                    let start = CACurrentMediaTime()
                    defer {
                        let end = CACurrentMediaTime()
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): cost \(end - start, format: .fixed(precision: 4))s to process \(records.count) feeds")
                    }
                    let oldSnapshot = diffableDataSource.snapshot()
                    var newSnapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem> = {
                        let newItems = records.map { record in
                            StatusItem.status(record)
                        }
                        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
                        snapshot.appendSections([.main])
                        snapshot.appendItems(newItems, toSection: .main)
                        return snapshot
                    }()

                    switch self.kind {
                    case .user:
                        let currentState = self.stateMachine.currentState
                        let hasMore = !(currentState is LoadOldestState.NoMore)
                        if hasMore, !newSnapshot.itemIdentifiers.contains(.bottomLoader) {
                            newSnapshot.appendItems([.bottomLoader], toSection: .main)
                        }
                    default:
                        assertionFailure()
                    }
                    
                    let hasChanges = newSnapshot.itemIdentifiers != oldSnapshot.itemIdentifiers
                    if !hasChanges {
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): snapshot not changes")
                        self.didLoadLatest.send()
                        return
                    } else {
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): snapshot has changes")
                    }
                    
                    self.updateDataSource(snapshot: newSnapshot, animatingDifferences: false)
                
                    self.didLoadLatest.send()
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot")
                }   // end Task
            }
            .store(in: &disposeBag)
    }
    
}
