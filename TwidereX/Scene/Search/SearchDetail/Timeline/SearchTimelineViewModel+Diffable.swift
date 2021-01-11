//
//  SearchTimelineViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import CoreData
import CoreDataStack

extension SearchTimelineViewModel {
    func setupDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency,
        timelinePostTableViewCellDelegate: TimelinePostTableViewCellDelegate
    ) {
        let timestampUpdatePublisher = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .share()
            .eraseToAnyPublisher()
        
        diffableDataSource = TimelineSection.tableViewDiffableDataSource(
            for: tableView,
            dependency: dependency,
            managedObjectContext: fetchedResultsController.managedObjectContext,
            timestampUpdatePublisher: timestampUpdatePublisher,
            timelinePostTableViewCellDelegate: timelinePostTableViewCellDelegate,
            timelineMiddleLoaderTableViewCellDelegate: nil,
            timelineHeaderTableViewCellDelegate: nil
        )
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension SearchTimelineViewModel: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let indexes = tweetIDs.value
        let tweets = fetchedResultsController.fetchedObjects ?? []
        guard tweets.count == indexes.count else { return }

        let items: [Item] = tweets
            .compactMap { tweet in
                indexes.firstIndex(of: tweet.id).map { index in (index, tweet) }
            }
            .sorted { $0.0 < $1.0 }
            .map { Item.tweet(objectID: $0.1.objectID) }
        self.items.value = items
    }
}

// FIXME:
extension SearchTimelineViewModel {
    
    enum SearchTimelineError: Swift.Error {
        case invalidAuthorization
        case invalidSearchText
        case invalidAnchorToLoadMore
    }
    
}
