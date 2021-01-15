//
//  SearchTimelineViewController+StatusProvider.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/13.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import TwitterAPI

// MARK: - StatusProvider
extension SearchTimelineViewController: StatusProvider {
    
    func tweet() -> Future<Tweet?, Never> {
        return Future { promise in promise(.success(nil)) }
    }
    
    func tweet(for cell: UITableViewCell, indexPath: IndexPath?) -> Future<Tweet?, Never> {
        return Future { promise in
            guard let diffableDataSource = self.viewModel.diffableDataSource else {
                assertionFailure()
                promise(.success(nil))
                return
            }
            guard let indexPath = indexPath ?? self.tableView.indexPath(for: cell),
                  let item = diffableDataSource.itemIdentifier(for: indexPath) else {
                promise(.success(nil))
                return
            }
            
            switch item {
            case .tweet(let objectID):
                let managedObjectContext = self.viewModel.tweetFetchedResultsController.fetchedResultsController.managedObjectContext
                managedObjectContext.perform {
                    let tweet = managedObjectContext.object(with: objectID) as? Tweet
                    promise(.success(tweet))
                }
            default:
                promise(.success(nil))
            }
        }
    }
    
    func tweet(for cell: UICollectionViewCell) -> Future<Tweet?, Never> {
        return Future { promise in promise(.success(nil)) }
    }
    
}
