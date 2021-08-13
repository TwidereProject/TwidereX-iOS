//
//  SearchMediaViewController+StatusProvider.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-13.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import TwitterSDK

// MARK: - StatusProvider
extension SearchMediaViewController: StatusProvider {
    
    func tweet() -> Future<Tweet?, Never> {
        return Future { promise in promise(.success(nil)) }
    }
    
    func tweet(for cell: UITableViewCell, indexPath: IndexPath?) -> Future<Tweet?, Never> {
        return Future { promise in promise(.success(nil)) }
    }
    
    func tweet(for cell: UICollectionViewCell) -> Future<Tweet?, Never> {
        return Future { promise in
            guard let diffableDataSource = self.viewModel.diffableDataSource,
                  let indexPath = self.collectionView.indexPath(for: cell),
                  let item = diffableDataSource.itemIdentifier(for: indexPath) else {
                promise(.success(nil))
                return
            }
            
            switch item {
            case .photoTweet(let objectID, _):
                let managedObjectContext = self.viewModel.fetchedResultsController.managedObjectContext
                managedObjectContext.perform {
                    let tweet = managedObjectContext.object(with: objectID) as? Tweet
                    promise(.success(tweet))
                }
            default:
                promise(.success(nil))
            }
        }
    }
    
}
