//
//  TweetConversationViewController+TweetProvider.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/10.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import TwitterAPI

// MARK: - TweetProvider
extension TweetConversationViewController: TweetProvider {
    
    func tweet(for cell: TimelinePostTableViewCell, indexPath: IndexPath?) -> Future<Tweet?, Never> {
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
    
    func tweet(for cell: ConversationPostTableViewCell) -> Future<Tweet?, Never> {
        return Future { promise in
            guard let diffableDataSource = self.viewModel.diffableDataSource,
                  let indexPath = self.tableView.indexPath(for: cell),
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
            default:
                promise(.success(nil))
            }
        }
    }
    
}
