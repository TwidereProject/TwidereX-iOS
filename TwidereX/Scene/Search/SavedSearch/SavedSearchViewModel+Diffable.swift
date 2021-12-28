//
//  SavedSearchViewModel+Diffable.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine

extension SavedSearchViewModel {
    func setupDiffableDataSource(
        tableView: UITableView
    ) {
        diffableDataSource = SearchSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: SearchSection.Configuration()
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<SearchSection, SearchItem>()
        snapshot.appendSections([.history])
        snapshot.appendItems([.loader(id: UUID())], toSection: .history)
        diffableDataSource?.apply(snapshot)
        
        Publishers.CombineLatest(
            savedSearchFetchedResultController.$records,
            $isSavedSearchFetched
        )
        .throttle(for: 0.3, scheduler: DispatchQueue.main, latest: true)
        .sink { [weak self] savedSearchRecords, isSavedSearchFetched in
            guard let self = self else { return }
            guard let diffableDataSource = self.diffableDataSource else { return }
            
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): incoming \(savedSearchRecords.count) saved search records")
            
            var snapshot = NSDiffableDataSourceSnapshot<SearchSection, SearchItem>()
            snapshot.appendSections([.history, .trend])
            
            // history
            let historyItems: [SearchItem] = savedSearchRecords.map { .history(record: $0) }
            snapshot.appendItems(historyItems, toSection: .history)
            if historyItems.isEmpty {
                if isSavedSearchFetched {
                    snapshot.appendItems([.noResults()], toSection: .history)
                } else {
                    snapshot.appendItems([.loader()], toSection: .history)
                }
            }
            
            diffableDataSource.apply(snapshot, animatingDifferences: false, completion: nil)
        }
        .store(in: &disposeBag)
    }
}
