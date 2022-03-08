//
//  CompositeListViewModel+Diffable.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-7.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import Combine
import TwidereCore
import GameplayKit

extension CompositeListViewModel {
    
    static let sectionItemLimit = 5
    
    func setupDiffableDataSource(
        tableView: UITableView
    ) {
        diffableDataSource = ListSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: ListSection.Configuration()
        )
        
        switch kind {
        case .lists(let user):
            bindListsDiffableDataSource(tableView: tableView, user: user)
        case .listed(let user):
            bindListedDiffableDataSource(tableView: tableView, user: user)
        }
    }
    
}

extension CompositeListViewModel {

    // lists:
    // - owned
    // - subscribed
    private func bindListsDiffableDataSource(
        tableView: UITableView,
        user: UserRecord
    ) {
        Publishers.CombineLatest(
            ownedListViewModel.fetchedResultController.$records,
            subscribedListViewModel.fetchedResultController.$records
        )
        .receive(on: DispatchQueue.main)
        .asyncMap { [weak self] ownedListRecords, subscribedListRecords -> NSDiffableDataSourceSnapshot<ListSection, ListItem>? in
            guard let self = self else { return nil }
        
            var snapshot = NSDiffableDataSourceSnapshot<ListSection, ListItem>()
            
            // section
            let ownedListSection: ListSection = {
                switch user {
                case .twitter:          return ListSection.twitter(kind: .owned)
                case .mastodon:         return ListSection.mastodon
                }
            }()
            snapshot.appendSections([ownedListSection])
            
            let _subscribedListSection: ListSection? = {
                switch user {
                case .twitter:          return ListSection.twitter(kind: .subscribed)
                case .mastodon:         return nil
                }
            }()
            if let subscribedListSection = _subscribedListSection {
                snapshot.appendSections([subscribedListSection])
            }
            
            // limit
            let sectionItemLimit: Int? = snapshot.numberOfSections > 1 ? CompositeListViewModel.sectionItemLimit : nil
            
            // owned list
            let ownedItems = ownedListRecords.map { ListItem.list(record: $0, style: .plain) }
            CompositeListViewModel.appendItemsToSnapshot(
                snapshot: &snapshot,
                items: ownedItems,
                section: ownedListSection,
                sectionLimit: sectionItemLimit,
                state: await self.ownedListViewModel.stateMachine.currentState
            )

            // subscribed list
            if let subscribedListSection = _subscribedListSection {
                let subscribedItems = subscribedListRecords.map { ListItem.list(record: $0, style: .user) }
                CompositeListViewModel.appendItemsToSnapshot(
                    snapshot: &snapshot,
                    items: subscribedItems,
                    section: subscribedListSection,
                    sectionLimit: sectionItemLimit,
                    state: await self.subscribedListViewModel.stateMachine.currentState
                )
            }
            
            return snapshot
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] snapshot in
            guard let self = self else { return }
            guard let snapshot = snapshot else { return }

            self.diffableDataSource?.apply(snapshot, animatingDifferences: false)
        }
        .store(in: &disposeBag)
    }
 
    // listed
    private func bindListedDiffableDataSource(
        tableView: UITableView,
        user: UserRecord
    ) {
        listedListViewModel.fetchedResultController.$records
            .asyncMap { [weak self] records -> NSDiffableDataSourceSnapshot<ListSection, ListItem>? in
            guard let self = self else { return nil }
        
            var snapshot = NSDiffableDataSourceSnapshot<ListSection, ListItem>()
            
            // section
            let _section: ListSection? = {
                switch user {
                case .twitter:          return ListSection.twitter(kind: .listed)
                case .mastodon:         return nil
                }
            }()
                
            // listed list
            if let section = _section {
                snapshot.appendSections([section])
                let items = records.map { ListItem.list(record: $0, style: .user) }
                CompositeListViewModel.appendItemsToSnapshot(
                    snapshot: &snapshot,
                    items: items,
                    section: section,
                    sectionLimit: nil,
                    state: await self.listedListViewModel.stateMachine.currentState
                )
            }

            return snapshot
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] snapshot in
            guard let self = self else { return }
            guard let snapshot = snapshot else { return }

            self.diffableDataSource?.apply(snapshot, animatingDifferences: false)
        }
        .store(in: &disposeBag)
    }
    
    private static func appendItemsToSnapshot(
        snapshot: inout NSDiffableDataSourceSnapshot<ListSection, ListItem>,
        items: [ListItem],
        section: ListSection,
        sectionLimit: Int?,
        state: GKState?
    ) {
        let limitItems = sectionLimit.flatMap({ Array(items.prefix($0)) }) ?? items
        snapshot.appendItems(limitItems, toSection: section)
        
        switch state {
        case .none:
            break
        case is ListViewModel.State.NoMore:
            if items.isEmpty {
                snapshot.appendItems([.noResults()], toSection: section)
            }
        default:
            if let sectionLimit = sectionLimit, items.count > sectionLimit {
                snapshot.appendItems([.showMore()], toSection: section)
            } else {
                snapshot.appendItems([.loader()], toSection: section)
            }
        }
    }
    
}
