//
//  MentionTimelineViewController+TweetProvider.swift
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
extension MentionTimelineViewController: TweetProvider {
    func tweet(for cell: TimelinePostTableViewCell) -> Future<Tweet?, Never> {
        return Future { promise in
            guard let diffableDataSource = self.viewModel.diffableDataSource,
                  let indexPath = self.tableView.indexPath(for: cell),
                  let item = diffableDataSource.itemIdentifier(for: indexPath) else {
                promise(.success(nil))
                return
            }
            
            switch item {
            case .mentionTimelineIndex(let objectID, _):
                let managedObjectContext = self.viewModel.fetchedResultsController.managedObjectContext
                managedObjectContext.perform {
                    let timelineIndex = managedObjectContext.object(with: objectID) as? MentionTimelineIndex
                    promise(.success(timelineIndex?.tweet))
                }
            default:
                promise(.success(nil))
            }
        }
    }
}
