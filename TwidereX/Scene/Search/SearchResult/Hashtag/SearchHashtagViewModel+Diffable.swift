//
//  SearchHashtagViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-5.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

extension SearchHashtagViewModel {
    func setupDiffableDataSource(
        tableView: UITableView
    ) {
        let configuration = HashtagSection.Configuration()
        diffableDataSource = HashtagSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: configuration
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<HashtagSection, HashtagItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
        
        $items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                guard let _ = self.diffableDataSource else { return }
                
                let count = items.count
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): incoming \(count) objects")
                Task {
                    let start = CACurrentMediaTime()
                    defer {
                        let end = CACurrentMediaTime()
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): cost \(end - start, format: .fixed(precision: 4))s to process \(count) feeds")
                    }
                    
                    var newSnapshot: NSDiffableDataSourceSnapshot<HashtagSection, HashtagItem> = {
                        var snapshot = NSDiffableDataSourceSnapshot<HashtagSection, HashtagItem>()
                        snapshot.appendSections([.main])
                        snapshot.appendItems(items, toSection: .main)
                        return snapshot
                    }()
                    
                    if let currentState = self.stateMachine.currentState {
                        switch currentState {
                        case is State.Idle, is State.Loading, is State.Fail:
                            newSnapshot.appendItems([.bottomLoader], toSection: .main)
                        case is State.NoMore:
                            break
                        default:
                            break
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
        snapshot: NSDiffableDataSourceSnapshot<HashtagSection, HashtagItem>,
        animatingDifferences: Bool
    ) async {
        await diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
}

extension SearchHashtagViewModel {
    func item(at indexPath: IndexPath) -> HashtagItem? {
        return diffableDataSource?.itemIdentifier(for: indexPath)
    }
}
