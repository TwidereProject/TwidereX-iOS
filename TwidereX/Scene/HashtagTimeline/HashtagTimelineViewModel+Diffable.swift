//
//  HashtagTimelineViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import AppShared

extension HashtagTimelineViewModel {
    func setupDiffableDataSource(
        tableView: UITableView,
        statusViewTableViewCellDelegate: StatusViewTableViewCellDelegate
    ) {
        let configuration = StatusSection.Configuration(
            statusViewTableViewCellDelegate: statusViewTableViewCellDelegate,
            timelineMiddleLoaderTableViewCellDelegate: nil,
            statusViewConfigurationContext: .init(
                dateTimeProvider: DateTimeSwiftProvider(),
                twitterTextProvider: OfficialTwitterTextProvider(),
                authenticationContext: context.authenticationService.$activeAuthenticationContext
            )
        )
        diffableDataSource = StatusSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: configuration
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems([.bottomLoader], toSection: .main)
        diffableDataSource?.apply(snapshot)
        
        statusRecordFetchedResultController.records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let _ = self.diffableDataSource else { return }

                let recordsCount = records.count
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): incoming \(recordsCount) objects")
                Task {
                    let start = CACurrentMediaTime()
                    defer {
                        let end = CACurrentMediaTime()
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): cost \(end - start, format: .fixed(precision: 4))s to process \(recordsCount) feeds")
                    }

                    var newSnapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem> = {
                        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
                        snapshot.appendSections([.main])
                        let newItems: [StatusItem] = records.map { .status($0) }
                        snapshot.appendItems(newItems, toSection: .main)
                        return snapshot
                    }()

                    if let currentState = await self.stateMachine.currentState {
                        switch currentState {
                        case is State.NoMore:
                            break
                        default:
                            newSnapshot.appendItems([.bottomLoader], toSection: .main)
                        }
                    }

                    await self.updateDataSource(snapshot: newSnapshot, animatingDifferences: false)
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot")
                }
            }
            .store(in: &disposeBag)
    }   // end func setupDiffableDataSource
    
    @MainActor
    private func updateDataSource(
        snapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>,
        animatingDifferences: Bool
    ) async {
        await diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
}
