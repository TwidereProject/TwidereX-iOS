//
//  AccountListViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-11.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreDataStack
import AlamofireImage

extension AccountListViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView,
        userTableViewCellDelegate: UserTableViewCellDelegate
    ) {
        diffableDataSource = UserSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: UserSection.Configuration(
                userTableViewCellDelegate: userTableViewCellDelegate
            )
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
        
        context.authenticationService.authenticationIndexes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authenticationIndexes in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
                snapshot.appendSections([.main])
                let items = authenticationIndexes.map { authenticationIndex -> UserItem in
                    let record = ManagedObjectRecord<AuthenticationIndex>(objectID: authenticationIndex.objectID)
                    return UserItem.authenticationIndex(record: record)
                }
                snapshot.appendItems(items, toSection: .main)
                diffableDataSource.apply(snapshot)
            }
            .store(in: &disposeBag)
    }
    
}
