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
            managedObjectContext: tweetFetchedResultsController.fetchedResultsController.managedObjectContext,
            timestampUpdatePublisher: timestampUpdatePublisher,
            timelinePostTableViewCellDelegate: timelinePostTableViewCellDelegate,
            timelineMiddleLoaderTableViewCellDelegate: nil,
            timelineHeaderTableViewCellDelegate: nil
        )
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
