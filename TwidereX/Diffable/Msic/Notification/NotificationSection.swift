//
//  NotificationSection.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/11.
//  Copyright © 2021 Twidere. All rights reserved.
//


import UIKit

enum NotificationSection: Hashable {
    case main
}

extension NotificationSection {
    
    struct Configuration {
        let statusViewTableViewCellDelegate: StatusViewTableViewCellDelegate
    }

    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<NotificationSection, NotificationItem> {
        return UITableViewDiffableDataSource<NotificationSection, NotificationItem>(tableView: tableView) { tableView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            
            // configure cell with item
            switch item {
            case .feed(let record):
                return context.managedObjectContext.performAndWait {
                    guard let feed = record.object(in: context.managedObjectContext) else {
                        assertionFailure()
                        return UITableViewCell()
                    }
                    
                    if let _ = feed.statusObject {
                        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                        configure(
                            tableView: tableView,
                            cell: cell,
                            viewModel: StatusTableViewCell.ViewModel(value: .feed(feed)),   //
                            configuration: configuration
                        )
                        return cell
                    } else if let notificationObject = feed.notificationObject {
                        return UITableViewCell()
                    } else {
                        assertionFailure()
                        return UITableViewCell()
                    }
                }   // end return context.managedObjectContext.performAndWait
                
            case .feedLoader(let record):
                return UITableViewCell()
//                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self), for: indexPath) as! TimelineMiddleLoaderTableViewCell
//                context.managedObjectContext.performAndWait {
//                    guard let feed = record.object(in: context.managedObjectContext) else { return }
//                    configure(
//                        cell: cell,
//                        feed: feed,
//                        configuration: configuration
//                    )
//                }
//                return cell

            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            }   // end switch
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
        cell.configure(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.statusViewTableViewCellDelegate
        )
    }
    
}
