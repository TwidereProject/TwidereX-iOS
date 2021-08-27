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
            case .homeTimelineFeed(let record):
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

            case .twitterStatus(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let status = record.object(in: context.managedObjectContext) else { return }
                    configure(
                        tableView: tableView,
                        cell: cell,
                        viewModel: StatusTableViewCell.ViewModel(value: .twitterStatus(status)),
                        configuration: configuration
                    )
                }
                return cell
            }
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
        cell.configuration(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.statusTableViewCellDelegate
        )
    }
    
}
