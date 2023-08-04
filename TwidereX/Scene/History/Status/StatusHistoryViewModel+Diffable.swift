//
//  StatusHistoryViewModel+Diffable.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-29.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import Combine

extension StatusHistoryViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView,
        statusViewTableViewCellDelegate: StatusViewTableViewCellDelegate
    ) {
        diffableDataSource = HistorySection.diffableDataSource(
            tableView: tableView,
            context: context,
            authContext: authContext,
            configuration: .init(
                statusViewTableViewCellDelegate: statusViewTableViewCellDelegate,
                userViewTableViewCellDelegate: nil,
                viewLayoutFramePublisher: $viewLayoutFrame
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
 
