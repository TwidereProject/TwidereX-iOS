//
//  TwitterUserOwnedListViewModel+Diffable.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-1.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import Combine

extension ListViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView
    ) {
        diffableDataSource = ListSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: ListSection.Configuration()
        )
        
        fetchedResultController.$records
            .receive(on: DispatchQueue.main)
            .asyncMap { [weak self] records -> NSDiffableDataSourceSnapshot<ListSection, ListItem>? in
                guard let self = self else { return nil }
                var snapshot = NSDiffableDataSourceSnapshot<ListSection, ListItem>()
                
                let section: ListSection = {
                    switch self.kind {
                    case .none:             return ListSection.twitter(kind: .owned)
                    case .owned:            return ListSection.twitter(kind: .owned)
                    case .subscribed:       return ListSection.twitter(kind: .subscribed)
                    case .listed:           return ListSection.twitter(kind: .listed)
                    }
                }()
                snapshot.appendSections([section])
                
                let items = records.map { ListItem.list(record: $0, style: .plain) }
                snapshot.appendItems(items, toSection: section)
                
                let currentState = await self.stateMachine.currentState
                switch currentState {
                case .none:
                    break
                case is State.NoMore:
                    if items.isEmpty {
                        snapshot.appendItems([.noResults()], toSection: section)
                    }
                default:
                    snapshot.appendItems([.loader()], toSection: section)
                }
                                
                return snapshot
            }
            .sink { [weak self] snapshot in
                guard let self = self else { return }
                guard let snapshot = snapshot else { return }
                self.diffableDataSource?.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &disposeBag)
    }
    
}
