//
//  NotificationSection.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/11.
//  Copyright © 2021 Twidere. All rights reserved.
//


import UIKit
import SwiftUI

enum NotificationSection: Hashable {
    case main
}

extension NotificationSection {
    
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
    ) -> UITableViewDiffableDataSource<NotificationSection, NotificationItem> {
        return UITableViewDiffableDataSource<NotificationSection, NotificationItem>(tableView: tableView) { tableView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            
            tableView.register(NotificationTableViewCell.self, forCellReuseIdentifier: String(describing: NotificationTableViewCell.self))
            // tableView.register(UserNotificationStyleTableViewCell.self, forCellReuseIdentifier: String(describing: UserNotificationStyleTableViewCell.self))
            tableView.register(TimelineMiddleLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self))
            tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
            
            // configure cell with item
            switch item {
            case .feed(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NotificationTableViewCell.self), for: indexPath) as! NotificationTableViewCell
                cell.statusViewTableViewCellDelegate = configuration.statusViewTableViewCellDelegate
                cell.userViewTableViewCellDelegate = configuration.userViewTableViewCellDelegate
                context.managedObjectContext.performAndWait {
                    guard let feed = record.object(in: context.managedObjectContext) else { return }
                    guard case let .notification(notification) = feed.content else { return }
                    let viewModel = NotificationView.ViewModel(
                        notification: notification,
                        authContext: authContext,
                        statusViewDelegate: cell,
                        userViewDelegate: cell,
                        viewLayoutFramePublisher: configuration.viewLayoutFramePublisher
                    )
                    cell.contentConfiguration = UIHostingConfiguration {
                        NotificationView(viewModel: viewModel)
                    }
                    .margins(.vertical, 0)  // remove vertical margins
                }
                return cell

            case .feedLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self), for: indexPath) as! TimelineMiddleLoaderTableViewCell
                cell.viewModel.isFetching = true
                return cell
                
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            }   // end switch
        }   // end return
    }   // end func
    
}


extension NotificationSection {
    
//    static func configure(
//        tableView: UITableView,
//        cell: StatusTableViewCell,
//        viewModel: StatusTableViewCell.ViewModel,
//        configuration: Configuration
//    ) {
//        cell.configure(
//            tableView: tableView,
//            viewModel: viewModel,
//            configurationContext: configuration.statusViewConfigurationContext,
//            delegate: configuration.statusViewTableViewCellDelegate
//        )
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
