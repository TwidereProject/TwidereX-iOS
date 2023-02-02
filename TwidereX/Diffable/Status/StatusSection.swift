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
import TwitterSDK

enum StatusSection: Hashable {
    case main
    case footer
}

extension StatusSection {
    
    static let logger = Logger(subsystem: "StatusSection", category: "Logic")
    
    struct Configuration {
        weak var statusViewTableViewCellDelegate: StatusViewTableViewCellDelegate?
        weak var timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate?
        let statusViewConfigurationContext: StatusView.ConfigurationContext
    }

    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<StatusSection, StatusItem> {
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(TimelineMiddleLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        
        return UITableViewDiffableDataSource<StatusSection, StatusItem>(tableView: tableView) { tableView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            
            // configure cell with item
            switch item {
            case .feed(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                setupStatusPollDataSource(
                    context: context,
                    statusView: cell.statusView,
                    configurationContext: configuration.statusViewConfigurationContext
                )
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
                    statusView: cell.statusView,
                    configurationContext: configuration.statusViewConfigurationContext
                )
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
                return StatusSection.dequeueConfiguredReusableCell(
                    context: context,
                    tableView: tableView,
                    indexPath: indexPath,
                    configuration: ThreadCellRegistrationConfiguration(
                        thread: thread,
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
        let configuration: Configuration
    }

    static func dequeueConfiguredReusableCell(
        context: AppContext,
        tableView: UITableView,
        indexPath: IndexPath,
        configuration: ThreadCellRegistrationConfiguration
    ) -> UITableViewCell {
        let managedObjectContext = context.managedObjectContext
        
        let configurationContext = configuration.configuration.statusViewConfigurationContext
        
        switch configuration.thread {
        case .root(let threadContext):
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusThreadRootTableViewCell.self), for: indexPath) as! StatusThreadRootTableViewCell
            setupStatusPollDataSource(
                context: context,
                statusView: cell.statusView,
                configurationContext: configurationContext
            )
            managedObjectContext.performAndWait {
                guard let status = threadContext.status.object(in: managedObjectContext) else { return }
                cell.configure(
                    tableView: tableView,
                    viewModel: StatusThreadRootTableViewCell.ViewModel(value: .statusObject(status)),
                    configurationContext: configurationContext,
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
                statusView: cell.statusView,
                configurationContext: configurationContext
            )
            managedObjectContext.performAndWait {
                guard let status = threadContext.status.object(in: managedObjectContext) else { return }
                cell.configure(
                    tableView: tableView,
                    viewModel: StatusTableViewCell.ViewModel(value: .statusObject(status)),
                    configurationContext: configurationContext,
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
        statusView: StatusView,
        configurationContext: PollOptionView.ConfigurationContext
    ) {
        let managedObjectContext = context.managedObjectContext
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
                    // check is the first option in poll to trigger update poll only once
                    if option.index == 0, option.poll.needsUpdate {
                        let authenticationContext = configurationContext.authContext.authenticationContext
                        switch (option, authenticationContext) {
                        case (.twitter(let object), .twitter(let authenticationContext)):
                            let status: ManagedObjectRecord<TwitterStatus> = .init(objectID: object.poll.status.objectID)
                            Task { [weak context] in
                                guard let context = context else { return }
                                let statusIDs: [Twitter.Entity.V2.Tweet.ID] = await context.managedObjectContext.perform {
                                    guard let _status = status.object(in: context.managedObjectContext) else { return [] }
                                    let status = _status.repost ?? _status
                                    return [status.id]
                                }
                                _ = try await context.apiService.twitterStatus(
                                    statusIDs: statusIDs,
                                    authenticationContext: authenticationContext
                                )
                            }   // end Task
                        case (.mastodon(let object), .mastodon(let authenticationContext)):
                            let status: ManagedObjectRecord<MastodonStatus> = .init(objectID: object.poll.status.objectID)
                            Task { [weak context] in
                                guard let context = context else { return }
                                _ = try await context.apiService.viewMastodonStatusPoll(
                                    status: status,
                                    authenticationContext: authenticationContext
                                )
                            }   // end Task
                        default:
                            assertionFailure()
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
            configurationContext: configuration.statusViewConfigurationContext,
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
