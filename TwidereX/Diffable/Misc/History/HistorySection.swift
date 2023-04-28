//
//  HistorySection.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-29.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import Combine
import CoreData
import CoreDataStack
import MetaTextKit
import TwitterSDK

enum HistorySection: Hashable {
    case group(identifer: String)
}

extension HistorySection {
    
    static let logger = Logger(subsystem: "StatusSection", category: "Logic")
    
    struct Configuration {
        weak var statusViewTableViewCellDelegate: StatusViewTableViewCellDelegate?
        weak var userViewTableViewCellDelegate: UserViewTableViewCellDelegate?
        let viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
    }
    
    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        authContext: AuthContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<HistorySection, HistoryItem> {
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: String(describing: UserTableViewCell.self))

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
                        cell.statusViewTableViewCellDelegate = configuration.statusViewTableViewCellDelegate
                        
                        let viewModel = StatusView.ViewModel(
                            status: status,
                            authContext: authContext,
                            delegate: cell,
                            viewLayoutFramePublisher: configuration.viewLayoutFramePublisher
                        )
                        cell.contentConfiguration = UIHostingConfiguration {
                            StatusView(viewModel: viewModel)
                        }
                        .margins(.vertical, 0)  // remove vertical margins
                        return cell
                    }
                    // user
                    if let user = history.userObject {
                        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserTableViewCell.self), for: indexPath) as! UserTableViewCell
                        cell.userViewTableViewCellDelegate = configuration.userViewTableViewCellDelegate

                        let _viewModel = UserView.ViewModel(
                            user: user,
                            authContext: authContext,
                            kind: .history,
                            delegate: cell
                        )
                        guard let viewModel = _viewModel else {
                            return UITableViewCell()
                        }
                        cell.contentConfiguration = UIHostingConfiguration {
                            UserView(viewModel: viewModel)
                        }
                        .margins(.vertical, 0)  // remove vertical margins
                        return cell
                    }

                    assertionFailure()
                    return UITableViewCell()
                }
                return cell
            }
        }
        
        return  diffableDataSource
    }   // end func
    
}

extension HistorySection {
    
//    static func configure(
//        tableView: UITableView,
//        cell: StatusTableViewCell,
//        viewModel: StatusTableViewCell.ViewModel,
//        configuration: Configuration
//    ) {
//        StatusSection.configure(
//            tableView: tableView,
//            cell: cell,
//            viewModel: viewModel,
//            configuration: .init(
//                statusViewTableViewCellDelegate: configuration.statusViewTableViewCellDelegate,
//                timelineMiddleLoaderTableViewCellDelegate: nil,
//                statusViewConfigurationContext: configuration.statusViewConfigurationContext
//            )
//        )
//    }
//
//    static func configure(
//        cell: UserTableViewCell,
//        viewModel: UserTableViewCell.ViewModel,
//        configuration: Configuration
//    ) {
//        UserSection.configure(
//            cell: cell,
//            viewModel: viewModel,
//            configuration: .init(
//                userViewTableViewCellDelegate: configuration.userViewTableViewCellDelegate,
//                userViewConfigurationContext: configuration.userViewConfigurationContext
//            )
//        )
//    }
    
}
