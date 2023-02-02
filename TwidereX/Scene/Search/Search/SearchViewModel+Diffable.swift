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

extension SearchViewModel {
    func setupDiffableDataSource(
        tableView: UITableView
    ) {
        diffableDataSource = SearchSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: SearchSection.Configuration()
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<SearchSection, SearchItem>()
        snapshot.appendSections([.history, .trend])
        snapshot.appendItems([.loader()], toSection: .history)
        snapshot.appendItems([.loader()], toSection: .trend)
        diffableDataSource?.apply(snapshot)
        
        let historyItems: AnyPublisher<[SearchItem], Never> = Publishers.CombineLatest(
            savedSearchViewModel.savedSearchFetchedResultController.$records,
            savedSearchViewModel.$isSavedSearchFetched
        )
        .map { records, isSavedSearchFetched in
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): incoming \(records.count) saved search records")
            
            let limit = 3
            var items: [SearchItem] = records.prefix(limit).map { .history(record: $0) }
            if records.isEmpty {
                if isSavedSearchFetched {
                    items.append(.noResults())
                } else {
                    items.append(.loader())
                }
            } else if records.count > limit {
                items.append(.showMore())
            }
            return items
        }
        .eraseToAnyPublisher()
        
        let trendItems: AnyPublisher<[SearchItem], Never> = Publishers.CombineLatest3(
            trendViewModel.trendService.$trendGroupRecords,
            trendViewModel.$trendGroupIndex,
            trendViewModel.$isTrendFetched
        )
        .map { trendGroupRecords, trendGroupIndex, isTrendFetched in
            let limit: Int = {
                switch trendGroupIndex {
                case .mastodon:
                    return 20   // display inline for most servers
                default:
                    return 5
                }
            }()
            let trends: [TrendObject] = trendGroupRecords[trendGroupIndex]?.trends ?? []
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): incoming \(trends.count) trend items")
            
            var items: [SearchItem] = trends.prefix(limit).map { .trend(trend: $0) }
            if trends.isEmpty {
                if isTrendFetched {
                    items.append(.noResults())
                } else {
                    items.append(.loader())
                }
            } else if trends.count > limit {
                items.append(.showMore())
            }
            return items
        }
        .eraseToAnyPublisher()
        
        Publishers.CombineLatest(
            historyItems,
            trendItems
        )
        .throttle(for: 0.3, scheduler: DispatchQueue.main, latest: true)
        .sink { [weak self] historyItems, trendItems in
            guard let self = self else { return }
            guard let diffableDataSource = self.diffableDataSource else { return }
                        
            var snapshot = NSDiffableDataSourceSnapshot<SearchSection, SearchItem>()
            snapshot.appendSections([.history, .trend])
            
            // history
            snapshot.appendItems(historyItems, toSection: .history)

            // trend
            snapshot.appendItems(trendItems.removingDuplicates(), toSection: .trend)
            
            diffableDataSource.apply(snapshot, animatingDifferences: false, completion: nil)
        }
        .store(in: &disposeBag)
    }
}

