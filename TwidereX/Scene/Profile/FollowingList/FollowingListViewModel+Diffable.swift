//
//  FollowingListViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import CoreData
import CoreDataStack
import AlamofireImage
import Kingfisher

extension FollowingListViewModel {
    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = MediaSection.tableViewDiffableDataSource(
            for: tableView,
            context: context,
            managedObjectContext: orderedTwitterUserFetchedResultsController.fetchedResultsController.managedObjectContext
        )
    }
}
