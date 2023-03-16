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
import TwidereCore

extension AccountListViewModel {
    
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
                    listMembershipViewModel: nil
                )
            )
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
        
        $items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }

                var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
                snapshot.appendSections([.main])
                snapshot.appendItems(items, toSection: .main)
                diffableDataSource.apply(snapshot)
            }
            .store(in: &disposeBag)
    }
    
}
