//
//  NotificationSection.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/11.
//  Copyright © 2021 Twidere. All rights reserved.
//


import UIKit
import AppShared
import TwidereUI

enum NotificationSection: Hashable {
    case main
}

extension NotificationSection {
    
    struct Configuration {
        weak var statusViewTableViewCellDelegate: StatusViewTableViewCellDelegate?
        weak var userViewTableViewCellDelegate: UserViewTableViewCellDelegate?
        let userViewConfigurationContext: UserView.ConfigurationContext
        let viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
    }

    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<NotificationSection, NotificationItem> {
        return UITableViewDiffableDataSource<NotificationSection, NotificationItem>(tableView: tableView) { tableView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            
            return UITableViewCell()
            
            // configure cell with item
//            switch item {
//            case .feed(let record):
//                return context.managedObjectContext.performAndWait {
//                    guard let feed = record.object(in: context.managedObjectContext) else {
//                        assertionFailure()
//                        return UITableViewCell()
//                    }
//
//                    switch feed.objectContent {
//                    case .status:
//                        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
//                        StatusSection.setupStatusPollDataSource(
//                            context: context,
//                            statusView: cell.statusView,
//                            configurationContext: configuration.statusViewConfigurationContext
//                        )
//                        configure(
//                            tableView: tableView,
//                            cell: cell,
//                            viewModel: StatusTableViewCell.ViewModel(value: .feed(feed)),
//                            configuration: configuration
//                        )
//                        return cell
//                    case .notification(let object):
//                        switch object {
//                        case .mastodon(let notification):
//                            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserNotificationStyleTableViewCell.self), for: indexPath) as! UserNotificationStyleTableViewCell
//                            let authenticationContext = configuration.statusViewConfigurationContext.authContext.authenticationContext
//                            let me = authenticationContext.user(in: context.managedObjectContext)
//                            let user: UserObject = .mastodon(object: notification.account)
//                            configure(
//                                cell: cell,
//                                viewModel: UserTableViewCell.ViewModel(
//                                    user: user,
//                                    me: me,
//                                    notification: .mastodon(object: notification)
//                                ),
//                                configuration: configuration
//                            )
//                            return cell
//                        }
//                    case .none:
//                        assertionFailure()
//                        return UITableViewCell()
//                    }
//                }   // end return context.managedObjectContext.performAndWait
//
//            case .feedLoader:
//                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self), for: indexPath) as! TimelineMiddleLoaderTableViewCell
//                cell.viewModel.isFetching = true
//                return cell
//
//            case .bottomLoader:
//                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
//                cell.activityIndicatorView.startAnimating()
//                return cell
//            }   // end switch
        }
    }
    
}


extension NotificationSection {
    
    static func configure(
        tableView: UITableView,
        cell: StatusTableViewCell,
        viewModel: StatusTableViewCell.ViewModel,
        configuration: Configuration
    ) {
//        cell.configure(
//            tableView: tableView,
//            viewModel: viewModel,
//            configurationContext: configuration.statusViewConfigurationContext,
//            delegate: configuration.statusViewTableViewCellDelegate
//        )
    }
    
    static func configure(
        cell: UserTableViewCell,
        viewModel: UserTableViewCell.ViewModel,
        configuration: Configuration
    ) {
        cell.configure(
            viewModel: viewModel,
            configurationContext: configuration.userViewConfigurationContext,
            delegate: configuration.userViewTableViewCellDelegate
        )
    }
}
