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
    }
    
    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<HistorySection, HistoryItem> {
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        
        let diffableDataSource = UITableViewDiffableDataSource<HistorySection, HistoryItem>(tableView: tableView) { tableView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            
            switch item {
            case .history(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                StatusSection.setupStatusPollDataSource(
                    context: context,
                    statusView: cell.statusView,
                    configurationContext: configuration.statusViewConfigurationContext
                )
                context.managedObjectContext.performAndWait {
                    guard let status = record.object(in: context.managedObjectContext)?.statusObject else { return }
                    configure(
                        tableView: tableView,
                        cell: cell,
                        viewModel: StatusTableViewCell.ViewModel(value: .statusObject(status)),
                        configuration: configuration
                    )
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
    
}
