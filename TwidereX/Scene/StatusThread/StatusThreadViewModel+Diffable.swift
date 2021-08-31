//
//  StatusThreadViewModel+Diffable.swift
//  StatusThreadViewModel+Diffable
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import CoreData
import CoreDataStack

extension StatusThreadViewModel {
    func setupDiffableDataSource(
        tableView: UITableView,
        statusTableViewCellDelegate: StatusTableViewCellDelegate,
        statusThreadRootTableViewCellDelegate: StatusThreadRootTableViewCellDelegate
    ) {
        let configuration = StatusSection.Configuration(
            statusTableViewCellDelegate: statusTableViewCellDelegate,
            statusThreadRootTableViewCellDelegate: statusThreadRootTableViewCellDelegate
        )
        diffableDataSource = StatusSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: configuration
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
        snapshot.appendSections([.main])
        if let root = self.root.value {
            let item = StatusItem.thread(root)
            snapshot.appendItems([item], toSection: .main)
        }
        diffableDataSource?.apply(snapshot)
        
        // trigger thread loading
        loadThreadStateMachine.enter(LoadThreadState.Prepare.self)
    }
}
