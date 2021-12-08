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
        weak var statusViewTableViewCellDelegate: StatusViewTableViewCellDelegate?
        weak var timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate?
    }

    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<StatusSection, StatusItem> {
        return UITableViewDiffableDataSource<StatusSection, StatusItem>(tableView: tableView) { tableView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            
            let activeAuthenticationContext = context.authenticationService.activeAuthenticationContext.eraseToAnyPublisher()
            
            // configure cell with item
            switch item {
            case .feed(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let feed = record.object(in: context.managedObjectContext) else { return }
                    configure(
                        tableView: tableView,
                        cell: cell,
                        viewModel: StatusTableViewCell.ViewModel(
                            value: .feed(feed),
                            activeAuthenticationContext: activeAuthenticationContext
                        ),
                        configuration: configuration
                    )
                }
                return cell
            case .feedLoader(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self), for: indexPath) as! TimelineMiddleLoaderTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let feed = record.object(in: context.managedObjectContext) else { return }
                    configure(
                        cell: cell,
                        feed: feed,
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
                            viewModel: StatusTableViewCell.ViewModel(
                                value: .twitterStatus(status),
                                activeAuthenticationContext: activeAuthenticationContext
                            ),
                            configuration: configuration
                        )
                    case .mastodon(let record):
                        guard let status = record.object(in: context.managedObjectContext) else { return }
                        configure(
                            tableView: tableView,
                            cell: cell,
                            viewModel: StatusTableViewCell.ViewModel(
                                value: .mastodonStatus(status),
                                activeAuthenticationContext: activeAuthenticationContext
                            ),
                            configuration: configuration
                        )
                    }   // end switch
                }
                return cell

            case .thread(let thread):
                return StatusSection.dequeueConfiguredReusableCell(
                    tableView: tableView,
                    indexPath: indexPath,
                    configuration: ThreadCellRegistrationConfiguration(
                        thread: thread,
                        managedObjectContext: context.managedObjectContext,
                        activeAuthenticationContext: activeAuthenticationContext,
                        configuration: configuration
                    )
                )
                
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
    
    struct ThreadCellRegistrationConfiguration {
        let thread: StatusItem.Thread
        let managedObjectContext: NSManagedObjectContext
        let activeAuthenticationContext: AnyPublisher<AuthenticationContext?, Never>
        let configuration: Configuration
    }

    static func dequeueConfiguredReusableCell(
        tableView: UITableView,
        indexPath: IndexPath,
        configuration: ThreadCellRegistrationConfiguration
    ) -> UITableViewCell {
        switch configuration.thread {
        case .root(let context):
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusThreadRootTableViewCell.self), for: indexPath) as! StatusThreadRootTableViewCell
            configuration.managedObjectContext.performAndWait {
                guard let status = context.status.object(in: configuration.managedObjectContext) else { return }
                cell.configure(
                    tableView: tableView,
                    viewModel: StatusThreadRootTableViewCell.ViewModel(
                        value: .statusObject(status),
                        activeAuthenticationContext: configuration.activeAuthenticationContext
                    ),
                    delegate: configuration.configuration.statusViewTableViewCellDelegate
                )
            }
            if context.displayUpperConversationLink {
                cell.setConversationLinkLineViewDisplay()
            }
            return cell
        case .reply(let context), .leaf(let context):
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
            configuration.managedObjectContext.performAndWait {
                guard let status = context.status.object(in: configuration.managedObjectContext) else { return }
                cell.configure(
                    tableView: tableView,
                    viewModel: StatusTableViewCell.ViewModel(
                        value: .statusObject(status),
                        activeAuthenticationContext: configuration.activeAuthenticationContext
                    ),
                    delegate: configuration.configuration.statusViewTableViewCellDelegate
                )
            }
            if context.displayUpperConversationLink {
                cell.setTopConversationLinkLineViewDisplay()
            }
            if context.displayBottomConversationLink {
                cell.setBottomConversationLinkLineViewDisplay()
            }
            return cell
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
            delegate: configuration.statusViewTableViewCellDelegate
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
            delegate: configuration.statusViewTableViewCellDelegate
        )
    }
    
    static func configure(
        cell: TimelineMiddleLoaderTableViewCell,
        feed: Feed,
        configuration: Configuration
    ) {
        cell.configure(
            feed: feed,
            delegate: configuration.timelineMiddleLoaderTableViewCellDelegate
        )
    }
    
}
