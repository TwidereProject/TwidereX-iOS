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
        let userTableViewCellDelegate: UserTableViewCellDelegate?
    }
    
    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
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
            case .user(let record, let style):
                let cell = dequeueReusableCell(tableView: tableView, indexPath: indexPath, style: style)
                context.managedObjectContext.performAndWait {
                    guard let user = record.object(in: context.managedObjectContext) else { return }
                    let authenticationContext = context.authenticationService.activeAuthenticationContext.value
                    let me = authenticationContext?.user(in: context.managedObjectContext)
                    let viewModel = UserTableViewCell.ViewModel(
                        user: user,
                        me: me
                    )
                    configure(
                        cell: cell,
                        viewModel: viewModel,
                        configuration: configuration
                    )
                }
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            }
        }
    }
    
}

extension UserSection {
    
    static func dequeueReusableCell(
        tableView: UITableView,
        indexPath: IndexPath,
        style: UserView.Style
    ) -> UserTableViewCell {
        switch style {
        case .plain:
            return tableView.dequeueReusableCell(withIdentifier: String(describing: UserFriendshipStyleTableViewCell.self), for: indexPath) as! UserFriendshipStyleTableViewCell
        case .friendship:
            return tableView.dequeueReusableCell(withIdentifier: String(describing: UserFriendshipStyleTableViewCell.self), for: indexPath) as! UserFriendshipStyleTableViewCell
        }
    }
    
    static func configure(
        cell: UserTableViewCell,
        viewModel: UserTableViewCell.ViewModel,
        configuration: Configuration
    ) {
        cell.configure(viewModel: viewModel)
        cell.delegate = configuration.userTableViewCellDelegate
    }
}

extension UserSection {
    
    @available(*, deprecated, message: "")
    static func configure(
        cell: AccountListTableViewCell,
        authenticationIndex: AuthenticationIndex
    ) {
        cell.configure(authenticationIndex: authenticationIndex)
    }
    
    @available(*, deprecated, message: "")
    static func configure(
        cell: UserFriendshipStyleTableViewCell,
        user: UserObject,
        me: UserObject?
    ) {
        let viewModel = UserTableViewCell.ViewModel(user: user, me: me)
        cell.configure(viewModel: viewModel)
    }
    
}
