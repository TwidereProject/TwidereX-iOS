//
//  UserHistoryViewModel+Diffable.swift
//  TwidereX
//
//  Created by MainasuK on 2022-8-1.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import Combine
import AppShared

extension UserHistoryViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView,
        userViewTableViewCellDelegate: UserViewTableViewCellDelegate
    ) {
        diffableDataSource = HistorySection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: .init(
                statusViewTableViewCellDelegate: nil,
                statusViewConfigurationContext: .init(
                    dateTimeProvider: DateTimeSwiftProvider(),
                    twitterTextProvider: OfficialTwitterTextProvider(),
                    authenticationContext: context.authenticationService.$activeAuthenticationContext
                ),
                userViewTableViewCellDelegate: userViewTableViewCellDelegate,
                userViewConfigurationContext: .init(
                    listMembershipViewModel: nil,
                    authenticationContext: context.authenticationService.activeAuthenticationContext
                )
            )
        )
        
        let snapshot = NSDiffableDataSourceSnapshot<HistorySection, HistoryItem>()
        diffableDataSource?.apply(snapshot)
        
        historyFetchedResultsController.$groupedRecords
            .receive(on: DispatchQueue.main)
            .sink { [weak self] groupedRecords in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }

                var snapshot = NSDiffableDataSourceSnapshot<HistorySection, HistoryItem>()
                for (identifier, records) in groupedRecords {
                    let section = HistorySection.group(identifer: identifier)
                    snapshot.appendSections([section])
                    let items: [HistoryItem] = records.map { .history(record: $0) }
                    snapshot.appendItems(items, toSection: section)
                }
                
                diffableDataSource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &disposeBag)
    }
    
}
