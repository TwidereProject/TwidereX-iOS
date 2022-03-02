//
//  TwitterUserOwnedListViewModel+Diffable.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-1.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import Combine

extension TwitterUserOwnedListViewModel {
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
            .asyncMap { records -> NSDiffableDataSourceSnapshot<ListSection, ListItem>? in
                var snapshot = NSDiffableDataSourceSnapshot<ListSection, ListItem>()
                
                let section = ListSection.twitter(kind: .owned)
                snapshot.appendSections([section])
                
                let items = records.map { ListItem.list(record: .twitter(record: $0)) }
                snapshot.appendItems(items, toSection: section)
                
                let currentState = await self.stateMachine.currentState
                switch currentState {
                case .none:
                    break
                case is TwitterUserOwnedListViewModel.State.NoMore:
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
