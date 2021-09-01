//
//  StatusSection.swift
//  StatusSection
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import MetaTextKit

enum StatusSection: Hashable {
    case main
}

extension StatusSection {
    
    static let logger = Logger(subsystem: "StatusSection", category: "Logic")
    
    struct Configuration {
        let statusTableViewCellDelegate: StatusTableViewCellDelegate
        let statusThreadRootTableViewCellDelegate: StatusThreadRootTableViewCellDelegate?
    }

    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<StatusSection, StatusItem> {
        return UITableViewDiffableDataSource<StatusSection, StatusItem>(tableView: tableView) { tableView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            
            // configure cell with item
            switch item {
            case .feed(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let feed = record.object(in: context.managedObjectContext) else { return }
                    configure(
                        tableView: tableView,
                        cell: cell,
                        viewModel: StatusTableViewCell.ViewModel(value: .feed(feed)),
                        configuration: configuration
                    )
                }
                return cell
                
            case .status(let status):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                context.managedObjectContext.performAndWait {
                    switch status {
                    case .twitter(let record):
                        guard let status = record.object(in: context.managedObjectContext) else { return }
                        configure(
                            tableView: tableView,
                            cell: cell,
                            viewModel: StatusTableViewCell.ViewModel(value: .twitterStatus(status)),
                            configuration: configuration
                        )
                    case .mastodon(let record):
                        guard let status = record.object(in: context.managedObjectContext) else { return }
                        configure(
                            tableView: tableView,
                            cell: cell,
                            viewModel: StatusTableViewCell.ViewModel(value: .mastodonStatus(status)),
                            configuration: configuration
                        )
                    }   // end switch
                }
                return cell

            case .thread(let thread):
                switch thread {
                case .root(let status):
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusThreadRootTableViewCell.self), for: indexPath) as! StatusThreadRootTableViewCell
                    context.managedObjectContext.performAndWait {
                        switch status {
                        case .twitter(let record):
                            guard let status = record.object(in: context.managedObjectContext) else { return }
                            configure(
                                tableView: tableView,
                                cell: cell,
                                viewModel: StatusThreadRootTableViewCell.ViewModel(value: .twitterStatus(status)),
                                configuration: configuration
                            )
                        case .mastodon(let record):
                            guard let status = record.object(in: context.managedObjectContext) else { return }
                            configure(
                                tableView: tableView,
                                cell: cell,
                                viewModel: StatusThreadRootTableViewCell.ViewModel(value: .mastodonStatus(status)),
                                configuration: configuration
                            )
                        }
                    }
                    return cell
                case .reply(let status):
                    fatalError()
                case .leaf(let status):
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                    context.managedObjectContext.performAndWait {
                        switch status {
                        case .twitter(let record):
                            guard let status = record.object(in: context.managedObjectContext) else { return }
                            configure(
                                tableView: tableView,
                                cell: cell,
                                viewModel: StatusTableViewCell.ViewModel(value: .twitterStatus(status)),
                                configuration: configuration
                            )
                        case .mastodon(let record):
                            guard let status = record.object(in: context.managedObjectContext) else { return }
                            configure(
                                tableView: tableView,
                                cell: cell,
                                viewModel: StatusTableViewCell.ViewModel(value: .mastodonStatus(status)),
                                configuration: configuration
                            )
                        }   // end switch
                    }
                    return cell
                }
                
            case .topLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell

            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            }   // end switch
        }
    }
}

extension StatusSection {
    
    static func configure(
        tableView: UITableView,
        cell: StatusTableViewCell,
        viewModel: StatusTableViewCell.ViewModel,
        configuration: Configuration
    ) {
        cell.configure(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.statusTableViewCellDelegate
        )
    }
    
    static func configure(
        tableView: UITableView,
        cell: StatusThreadRootTableViewCell,
        viewModel: StatusThreadRootTableViewCell.ViewModel,
        configuration: Configuration
    ) {
        cell.configure(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.statusThreadRootTableViewCellDelegate
        )
    }
    
}
