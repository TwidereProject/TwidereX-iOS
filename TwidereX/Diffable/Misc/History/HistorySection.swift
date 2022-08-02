//
//  HistorySection.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-29.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import MetaTextKit
import TwidereUI
import AppShared
import TwitterSDK

enum HistorySection: Hashable {
    case group(identifer: String)
}

extension HistorySection {
    
    static let logger = Logger(subsystem: "StatusSection", category: "Logic")
    
    struct Configuration {
        weak var statusViewTableViewCellDelegate: StatusViewTableViewCellDelegate?
        let statusViewConfigurationContext: StatusView.ConfigurationContext
        
        weak var userViewTableViewCellDelegate: UserViewTableViewCellDelegate?
        let userViewConfigurationContext: UserView.ConfigurationContext
    }
    
    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<HistorySection, HistoryItem> {
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(UserRelationshipStyleTableViewCell.self, forCellReuseIdentifier: String(describing: UserRelationshipStyleTableViewCell.self))

        let diffableDataSource = UITableViewDiffableDataSource<HistorySection, HistoryItem>(tableView: tableView) { tableView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            
            switch item {
            case .history(let record):
                let cell: UITableViewCell = context.managedObjectContext.performAndWait {
                    guard let history = record.object(in: context.managedObjectContext) else {
                        assertionFailure()
                        return UITableViewCell()
                    }
                    // status
                    if let status = history.statusObject {
                        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                        StatusSection.setupStatusPollDataSource(
                            context: context,
                            statusView: cell.statusView,
                            configurationContext: configuration.statusViewConfigurationContext
                        )
                        configure(
                            tableView: tableView,
                            cell: cell,
                            viewModel: StatusTableViewCell.ViewModel(value: .statusObject(status)),
                            configuration: configuration
                        )
                        return cell
                    }
                    // user
                    if let user = history.userObject {
                        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserRelationshipStyleTableViewCell.self), for: indexPath) as! UserRelationshipStyleTableViewCell
                        let authenticationContext = context.authenticationService.activeAuthenticationContext
                        let me = authenticationContext?.user(in: context.managedObjectContext)
                        let viewModel = UserTableViewCell.ViewModel(
                            user: user,
                            me: me,
                            notification: nil
                        )
                        configure(
                            cell: cell,
                            viewModel: viewModel,
                            configuration: configuration
                        )
                        return cell
                    }
                    
                    return UITableViewCell()
                }
                return cell
            }
        }
        
        return  diffableDataSource
    }   // end func
    
}

extension HistorySection {
    
    static func configure(
        tableView: UITableView,
        cell: StatusTableViewCell,
        viewModel: StatusTableViewCell.ViewModel,
        configuration: Configuration
    ) {
        StatusSection.configure(
            tableView: tableView,
            cell: cell,
            viewModel: viewModel,
            configuration: .init(
                statusViewTableViewCellDelegate: configuration.statusViewTableViewCellDelegate,
                timelineMiddleLoaderTableViewCellDelegate: nil,
                statusViewConfigurationContext: configuration.statusViewConfigurationContext
            )
        )
    }
    
    static func configure(
        cell: UserTableViewCell,
        viewModel: UserTableViewCell.ViewModel,
        configuration: Configuration
    ) {
        UserSection.configure(
            cell: cell,
            viewModel: viewModel,
            configuration: .init(
                userViewTableViewCellDelegate: configuration.userViewTableViewCellDelegate,
                userViewConfigurationContext: configuration.userViewConfigurationContext
            )
        )
    }
    
}
