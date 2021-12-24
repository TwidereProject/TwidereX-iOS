//
//  SearchViewModel+Diffable.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-22.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import TwidereCore
import Meta

extension SearchViewModel {
    func setupDiffableDataSource(
        tableView: UITableView
    ) {
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.register(SearchHistoryTableViewCell.self, forCellReuseIdentifier: String(describing: SearchHistoryTableViewCell.self))
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) {
            [weak self] tableView, indexPath, item in
            guard let self = self else { return UITableViewCell() }
            switch item {
            case .history(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchHistoryTableViewCell.self), for: indexPath) as! SearchHistoryTableViewCell
                self.context.managedObjectContext.performAndWait {
                    guard let object = record.object(in: self.context.managedObjectContext) else { return }
                    SearchViewModel.configure(cell: cell, object: object)
                }
                return cell
            case .trend:
                return UITableViewCell()
            case .loader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                return cell
            }
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<SearchSection, SearchItem>()
        snapshot.appendSections([.history, .trend])
        snapshot.appendItems([.loader(id: UUID())], toSection: .history)
        snapshot.appendItems([.loader(id: UUID())], toSection: .trend)
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
            
            let historyItems: [SearchItem] = savedSearchRecords.map { .history(record: $0) }
            snapshot.appendItems(historyItems, toSection: .history)
            
            diffableDataSource.apply(snapshot, animatingDifferences: false, completion: nil)
        }
        .store(in: &disposeBag)
    }
    
}

extension SearchViewModel {
    private static func configure(
        cell: SearchHistoryTableViewCell,
        object: SavedSearchObject
    ) {
        switch object {
        case .twitter(let history):
            let metaContent = Meta.convert(from: .plaintext(string: history.name))
            cell.metaLabel.configure(content: metaContent)
        }
    }
}
