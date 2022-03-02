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
        
        $user
            .flatMap { [weak self] user -> AnyPublisher<NSDiffableDataSourceSnapshot<ListSection, ListItem>?, Never> in
                guard let self = self else {
                    return Just(nil).eraseToAnyPublisher()
                }
                switch user {
                case .none:
                    return Just(nil).eraseToAnyPublisher()
                case .twitter:
                    switch self.kind {
                    case .lists:
                        return self.twitterUserOwnedListViewModel.fetchedResultController.$records
                            .asyncMap { records in
                                let limit = 5
                                var snapshot = NSDiffableDataSourceSnapshot<ListSection, ListItem>()
                                
                                // owned
                                let ownedListSection = ListSection.twitter(kind: .owned)
                                snapshot.appendSections([ownedListSection])
                                
                                let ownedItems = records.map { ListItem.list(record: .twitter(record: $0)) }
                                snapshot.appendItems(Array(ownedItems.prefix(limit)), toSection: ownedListSection)
                                
                                if ownedItems.isEmpty {
                                    let currentState = await self.twitterUserOwnedListViewModel.stateMachine.currentState
                                    switch currentState {
                                    case .none:
                                        break
                                    case is TwitterUserOwnedListViewModel.State.NoMore:
                                        if ownedItems.isEmpty {
                                            snapshot.appendItems([.noResults()], toSection: ownedListSection)
                                        }
                                    default:
                                        snapshot.appendItems([.loader()], toSection: ownedListSection)
                                    }
                                } else if ownedItems.count > limit {
                                    snapshot.appendItems([.showMore()], toSection: ownedListSection)
                                }
                                
                                // subscribed
                                // let subscribedListSection = ListSection.twitter(kind: .subscribed)
                                // snapshot.appendSections([subscribedListSection])

                                return snapshot
                            }
                            .eraseToAnyPublisher()
                    case .listed:
                        return Just(nil).eraseToAnyPublisher()
                    }
                    
                case .mastodon:
                    return Just(nil).eraseToAnyPublisher()
                }
            }
            .sink { [weak self] snapshot in
                guard let self = self else { return }
                guard let snapshot = snapshot else { return }
                
                self.diffableDataSource?.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &disposeBag)
    }
}
