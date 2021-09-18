//
//  TweetConversationViewController+StatusProvider.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/10.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import TwitterSDK

// MARK: - StatusProvider
extension TweetConversationViewController: StatusProvider {
    
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
            case .root(let objectID):
                let managedObjectContext = self.context.managedObjectContext
                managedObjectContext.perform {
                    let tweet = managedObjectContext.object(with: objectID) as? Tweet
                    promise(.success(tweet))
                }
            case .reply(let objectID):
                let managedObjectContext = self.context.managedObjectContext
                managedObjectContext.perform {
                    let tweet = managedObjectContext.object(with: objectID) as? Tweet
                    promise(.success(tweet))
                }
            case .leaf(let objectID, _):
                let managedObjectContext = self.context.managedObjectContext
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
