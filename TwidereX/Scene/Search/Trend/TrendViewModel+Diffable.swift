//
//  TrendViewModel+Diffable.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-28.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine

extension TrendViewModel {
    func setupDiffableDataSource(
        tableView: UITableView
    ) {
        diffableDataSource = SearchSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: SearchSection.Configuration(
                viewLayoutFramePublisher: $viewLayoutFrame
            )
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<SearchSection, SearchItem>()
        snapshot.appendSections([.trend])
        snapshot.appendItems([.loader()], toSection: .trend)
        diffableDataSource?.apply(snapshot)
        
        let trendItems: AnyPublisher<[SearchItem], Never> = Publishers.CombineLatest(
            trendService.$trendGroupRecords,
            $trendGroupIndex
        )
        .map { trendGroupRecords, trendGroupIndex in
            let trendItems: [SearchItem] = trendGroupRecords[trendGroupIndex]
                .flatMap { group in
                    return group.trends
                        .removingDuplicates()
                        .map { .trend(trend: $0) }
                } ?? []
            return trendItems
        }
        .eraseToAnyPublisher()
        
        Publishers.CombineLatest(
            trendItems,
            $isTrendFetched
        )
        .throttle(for: 0.3, scheduler: DispatchQueue.main, latest: true)
        .sink { [weak self] trendItems, isTrendFetched in
            guard let self = self else { return }
            guard let diffableDataSource = self.diffableDataSource else { return }
            
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): incoming \(trendItems.count) trend items")
            
            var snapshot = NSDiffableDataSourceSnapshot<SearchSection, SearchItem>()
            snapshot.appendSections([.history, .trend])
            
            // trend
            snapshot.appendItems(trendItems, toSection: .trend)
            if trendItems.isEmpty {
                if isTrendFetched {
                    snapshot.appendItems([.noResults()], toSection: .trend)
                } else {
                    snapshot.appendItems([.loader()], toSection: .trend)
                }
            }
            
            diffableDataSource.apply(snapshot, animatingDifferences: false, completion: nil)
        }
        .store(in: &disposeBag)
    }
}
