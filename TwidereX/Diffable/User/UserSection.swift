//
//  UserSection.swift
//  UserSection
//
//  Created by Cirno MainasuK on 2021-8-25.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import SwiftUI
import Combine
import CoreDataStack

enum UserSection {
    case main
}

extension UserSection {
    
    struct Configuration {
        weak var userViewTableViewCellDelegate: UserViewTableViewCellDelegate?
    }
    
    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        authContext: AuthContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<UserSection, UserItem> {
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: String(describing: UserTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))

        return UITableViewDiffableDataSource<UserSection, UserItem>(tableView: tableView) { tableView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserTableViewCell.self), for: indexPath) as! UserTableViewCell
            cell.userViewTableViewCellDelegate = configuration.userViewTableViewCellDelegate
            
            // configure cell with item
            switch item {
            case .authenticationIndex(let record):
                context.managedObjectContext.performAndWait {
                    guard let authenticationIndex = record.object(in: context.managedObjectContext) else { return }
                    guard let me = authenticationIndex.user else { return }
                    let _viewModel = UserView.ViewModel(
                        user: me,
                        authContext: authContext,
                        kind: .account,
                        delegate: cell
                    )
                    guard let viewModel = _viewModel else { return }
                    cell.contentConfiguration = UIHostingConfiguration {
                        UserView(viewModel: viewModel)
                    }
                    .margins(.vertical, 0)  // remove vertical margins
                }
            case .user(let record, let kind):
                context.managedObjectContext.performAndWait {
                    guard let user = record.object(in: context.managedObjectContext) else { return }
                    let _viewModel = UserView.ViewModel(
                        user: user,
                        authContext: authContext,
                        kind: kind,
                        delegate: cell
                    )
                    guard let viewModel = _viewModel else { return }
                    cell.contentConfiguration = UIHostingConfiguration {
                        UserView(viewModel: viewModel)
                    }
                    .margins(.vertical, 0)  // remove vertical margins
                }
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            }   // end switch
            
            return cell
        }
    }   // end func
    
}

extension UserSection {
    
//    static func dequeueReusableCell(
//        tableView: UITableView,
//        indexPath: IndexPath,
//        style: UserView.Style
//    ) -> UserTableViewCell {
//        switch style {
//        case .account:
//            return tableView.dequeueReusableCell(withIdentifier: String(describing: UserAccountStyleTableViewCell.self), for: indexPath) as! UserAccountStyleTableViewCell
//        case .relationship:
//            return tableView.dequeueReusableCell(withIdentifier: String(describing: UserRelationshipStyleTableViewCell.self), for: indexPath) as! UserRelationshipStyleTableViewCell
//        case .friendship:
//            return tableView.dequeueReusableCell(withIdentifier: String(describing: UserFriendshipStyleTableViewCell.self), for: indexPath) as! UserFriendshipStyleTableViewCell
//        case .notification:
//            return tableView.dequeueReusableCell(withIdentifier: String(describing: UserNotificationStyleTableViewCell.self), for: indexPath) as! UserNotificationStyleTableViewCell
//        case .mentionPick:
//            return tableView.dequeueReusableCell(withIdentifier: String(describing: UserMentionPickStyleTableViewCell.self), for: indexPath) as! UserMentionPickStyleTableViewCell
//        case .listMember:
//            return tableView.dequeueReusableCell(withIdentifier: String(describing: UserListMemberStyleTableViewCell.self), for: indexPath) as! UserListMemberStyleTableViewCell
//        case .addListMember:
//            return tableView.dequeueReusableCell(withIdentifier: String(describing: UserAddListMemberStyleTableViewCell.self), for: indexPath) as! UserAddListMemberStyleTableViewCell
//        }
//    }
    
//    static func configure(
//        cell: UserTableViewCell,
//        viewModel: UserTableViewCell.ViewModel,
//        configuration: Configuration
//    ) {
//        cell.configure(
//            viewModel: viewModel,
//            configurationContext: configuration.userViewConfigurationContext,
//            delegate: configuration.userViewTableViewCellDelegate
//        )
//    }
}
