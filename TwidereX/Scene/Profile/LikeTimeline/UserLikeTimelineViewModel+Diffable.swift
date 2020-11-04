//
//  UserLikeTimelineViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-4.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import CoreData
import CoreDataStack

extension UserLikeTimelineViewModel {
    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource<TimelineSection, Item>(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let userID = self.userID.value else {
                assertionFailure()
                return nil
            }
            
            switch item {
            case .tweet(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePostTableViewCell.self), for: indexPath) as! TimelinePostTableViewCell
                
                // configure cell
                let managedObjectContext = self.fetchedResultsController.managedObjectContext
                managedObjectContext.performAndWait {
                    let tweet = managedObjectContext.object(with: objectID) as! Tweet
                    UserLikeTimelineViewModel.configure(cell: cell, tweet: tweet, userID: userID, requestUserID: self.currentTwitterAuthentication.value?.userID ?? "")
                }
                cell.delegate = self.timelinePostTableViewCellDelegate
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.isHidden = false
                cell.activityIndicatorView.startAnimating()
                cell.loadMoreButton.isHidden = true
                return cell
            default:
                assertionFailure()
                return nil
            }
        }
    }
    
}

extension UserLikeTimelineViewModel {
    
    private static func configure(cell: TimelinePostTableViewCell, tweet: Tweet, userID: String, requestUserID: String) {
        HomeTimelineViewModel.configure(cell: cell, tweet: tweet, requestUserID: requestUserID)
        internalConfigure(cell: cell, tweet: tweet, userID: userID)
    }
    
    private static func internalConfigure(cell: TimelinePostTableViewCell, tweet: Tweet, userID: String) {
        // tweet date updater
        let createdAt = (tweet.retweet ?? tweet).createdAt
        NotificationCenter.default.publisher(for: UserLikeTimelineViewModel.secondStepTimerTriggered, object: nil)
            .sink { notification in
                guard let incomingUserID = notification.userInfo?["userID"] as? String,
                      incomingUserID == userID else { return }
                cell.timelinePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            }
            .store(in: &cell.disposeBag)
        
        // quote date updater
        let quote = tweet.retweet?.quote ?? tweet.quote
        if let quote = quote {
            let createdAt = quote.createdAt
            cell.timelinePostView.quotePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            NotificationCenter.default.publisher(for: UserLikeTimelineViewModel.secondStepTimerTriggered, object: nil)
                .sink { notification in
                    guard let incomingUserID = notification.userInfo?["userID"] as? String,
                          incomingUserID == userID else { return }
                    cell.timelinePostView.quotePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
                }
                .store(in: &cell.disposeBag)
        }
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension UserLikeTimelineViewModel: NSFetchedResultsControllerDelegate {
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
