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
import TwidereUI
import AppShared

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
                setupStatusPollDataSource(
                    context: context,
                    managedObjectContext: context.managedObjectContext,
                    statusView: cell.statusView,
                    configurationContext: PollOptionView.ConfigurationContext(
                        dateTimeProvider: DateTimeSwiftProvider(),
                        activeAuthenticationContext: activeAuthenticationContext
                    )
                )
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
                setupStatusPollDataSource(
                    context: context,
                    managedObjectContext: context.managedObjectContext,
                    statusView: cell.statusView,
                    configurationContext: PollOptionView.ConfigurationContext(
                        dateTimeProvider: DateTimeSwiftProvider(),
                        activeAuthenticationContext: activeAuthenticationContext
                    )
                )
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
                    context: context,
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
        context: AppContext,
        tableView: UITableView,
        indexPath: IndexPath,
        configuration: ThreadCellRegistrationConfiguration
    ) -> UITableViewCell {
        switch configuration.thread {
        case .root(let threadContext):
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusThreadRootTableViewCell.self), for: indexPath) as! StatusThreadRootTableViewCell
            setupStatusPollDataSource(
                context: context,
                managedObjectContext: configuration.managedObjectContext,
                statusView: cell.statusView,
                configurationContext: PollOptionView.ConfigurationContext(
                    dateTimeProvider: DateTimeSwiftProvider(),
                    activeAuthenticationContext: configuration.activeAuthenticationContext
                )
            )
            configuration.managedObjectContext.performAndWait {
                guard let status = threadContext.status.object(in: configuration.managedObjectContext) else { return }
                cell.configure(
                    tableView: tableView,
                    viewModel: StatusThreadRootTableViewCell.ViewModel(
                        value: .statusObject(status),
                        activeAuthenticationContext: configuration.activeAuthenticationContext
                    ),
                    delegate: configuration.configuration.statusViewTableViewCellDelegate
                )
            }
            if threadContext.displayUpperConversationLink {
                cell.setConversationLinkLineViewDisplay()
            }
            return cell
        case .reply(let threadContext),
             .leaf(let threadContext):
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
            setupStatusPollDataSource(
                context: context,
                managedObjectContext: configuration.managedObjectContext,
                statusView: cell.statusView,
                configurationContext: PollOptionView.ConfigurationContext(
                    dateTimeProvider: DateTimeSwiftProvider(),
                    activeAuthenticationContext: configuration.activeAuthenticationContext
                )
            )
            configuration.managedObjectContext.performAndWait {
                guard let status = threadContext.status.object(in: configuration.managedObjectContext) else { return }
                cell.configure(
                    tableView: tableView,
                    viewModel: StatusTableViewCell.ViewModel(
                        value: .statusObject(status),
                        activeAuthenticationContext: configuration.activeAuthenticationContext
                    ),
                    delegate: configuration.configuration.statusViewTableViewCellDelegate
                )
            }
            if threadContext.displayUpperConversationLink {
                cell.setTopConversationLinkLineViewDisplay()
            }
            if threadContext.displayBottomConversationLink {
                cell.setBottomConversationLinkLineViewDisplay()
            }
            return cell
        }
    }
    
    public static func setupStatusPollDataSource(
        context: AppContext,
        managedObjectContext: NSManagedObjectContext,
        statusView: StatusView,
        configurationContext: PollOptionView.ConfigurationContext
    ) {
        statusView.pollTableViewDiffableDataSource = UITableViewDiffableDataSource<PollSection, PollItem>(tableView: statusView.pollTableView) { tableView, indexPath, item in
            switch item {
            case .option(let record):
                // Fix cell reuse animation issue
                let cell: PollOptionTableViewCell = {
                    let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PollOptionTableViewCell.self) + "@\(indexPath.row)#\(indexPath.section)") as? PollOptionTableViewCell
                    _cell?.prepareForReuse()
                    return _cell ?? PollOptionTableViewCell()
                }()
                
                managedObjectContext.performAndWait {
                    guard let option = record.object(in: managedObjectContext) else {
                        assertionFailure()
                        return
                    }
                    cell.optionView.configure(
                        pollOption: option,
                        configurationContext: configurationContext
                    )
                    
                    // trigger update if needs
                    let needsUpdatePoll: Bool = {
                        // check first option in poll to trigger update poll only once
                        guard option.index == 0 else { return false }
                        
                        let poll = option.poll
                        guard !poll.expired else {
                            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): poll expired. Skip update poll \(poll.id)")
                            return false
                        }
                        
                        let now = Date()
                        let timeIntervalSinceUpdate = now.timeIntervalSince(poll.updatedAt)
                        #if DEBUG
                        let autoRefreshTimeInterval: TimeInterval = 3 // speedup testing
                        #else
                        let autoRefreshTimeInterval: TimeInterval = 30
                        #endif
                        
                        guard timeIntervalSinceUpdate > autoRefreshTimeInterval else {
                            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): skip update poll \(poll.id) due to recent updated")
                            return false
                        }
                        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update poll \(poll.id)…")
                        return true
                    }()
                    
                    if needsUpdatePoll,
                       case let .mastodon(authenticationContext) = context.authenticationService.activeAuthenticationContext.value
                    {
                        let status: ManagedObjectRecord<MastodonStatus> = .init(objectID: option.poll.status.objectID)
                        Task { [weak context] in
                            guard let context = context else { return }
                            _ = try await context.apiService.viewMastodonStatusPoll(
                                status: status,
                                authenticationContext: authenticationContext
                            )
                        }
                    }
                }   // end managedObjectContext.performAndWait
                return cell
            }
        }
        var _snapshot = NSDiffableDataSourceSnapshot<PollSection, PollItem>()
        _snapshot.appendSections([.main])
        statusView.pollTableViewDiffableDataSource?.applySnapshotUsingReloadData(_snapshot)
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
