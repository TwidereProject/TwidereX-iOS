//
//  ListUserViewModel+Diffable.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-11.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import Combine
import TwidereUI

extension ListUserViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView,
        userViewTableViewCellDelegate: UserViewTableViewCellDelegate
    ) {
        diffableDataSource = UserSection.diffableDataSource(
            tableView: tableView,
            context: context,
            authContext: authContext,
            configuration: UserSection.Configuration(
                userViewTableViewCellDelegate: userViewTableViewCellDelegate,
                userViewConfigurationContext: .init(
                    authContext: authContext,
                    listMembershipViewModel: listMembershipViewModel
                )
            )
        )
        
        fetchedResultController.$records
            .receive(on: DispatchQueue.main)
            .asyncMap { [weak self] records -> NSDiffableDataSourceSnapshot<UserSection, UserItem>? in
                guard let self = self else { return nil }
                var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()

                snapshot.appendSections([.main])

                let items = records.map { UserItem.user(record: $0, style: .listMember) }
                snapshot.appendItems(items, toSection: .main)

                let currentState = await self.stateMachine.currentState
                switch currentState {
                case .none:
                    break
                case is State.NoMore:
                    if items.isEmpty {
                        // TODO: add no results item
                        // snapshot.appendItems([.noResults()], toSection: .main)
                    }
                default:
                    snapshot.appendItems([.bottomLoader], toSection: .main)
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
