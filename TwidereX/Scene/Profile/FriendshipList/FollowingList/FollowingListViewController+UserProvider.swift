//
//  FollowingListViewController+UserProvider.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-24.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreData
import CoreDataStack

extension FollowingListViewController: UserProvider {
    func twitterUser(for cell: UITableViewCell, indexPath: IndexPath?) -> Future<TwitterUser?, Never> {
        return Future { promise in
            guard let diffableDataSource = self.viewModel.diffableDataSource else {
                assertionFailure()
                promise(.success(nil))
                return
            }
            guard let indexPath = indexPath ?? self.tableView.indexPath(for: cell),
                  let item = diffableDataSource.itemIdentifier(for: indexPath) else {
                assertionFailure()
                promise(.success(nil))
                return
            }
            
            switch item {
            case .twitterUser(let objectID):
                let managedObjectContext = self.viewModel.orderedTwitterUserFetchedResultsController.fetchedResultsController.managedObjectContext
                managedObjectContext.perform {
                    let twitterUser = managedObjectContext.object(with: objectID) as? TwitterUser
                    promise(.success(twitterUser))
                }
            default:
                promise(.success(nil))
            }
        }
    }
}
