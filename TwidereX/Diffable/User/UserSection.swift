//
//  UserSection.swift
//  UserSection
//
//  Created by Cirno MainasuK on 2021-8-25.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreDataStack

enum UserSection {
    case main
}

extension UserSection {
    
    struct Configuration {
        let accountListTableViewCellDelegate: AccountListTableViewCellDelegate
    }
    
    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext
    ) -> UITableViewDiffableDataSource<UserSection, UserItem> {
        return UITableViewDiffableDataSource<UserSection, UserItem>(tableView: tableView) { tableView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            
            // configure cell with item
            switch item {
            case .authenticationIndex(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AccountListTableViewCell.self), for: indexPath) as! AccountListTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let authenticationIndex = record.object(in: context.managedObjectContext) else { return }
                    configure(cell: cell, authenticationIndex: authenticationIndex)
                }
                return cell
            }
        }
    }
}

extension UserSection {
    
    static func configure(
        cell: AccountListTableViewCell,
        authenticationIndex: AuthenticationIndex
    ) {
        cell.configure(authenticationIndex: authenticationIndex)
    }
    
}
