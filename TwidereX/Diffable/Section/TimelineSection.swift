//
//  TimelineSection.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-9.
//

import UIKit
import Combine
import CoreData
import CoreDataStack

enum TimelineSection: Equatable, Hashable {
    case main
}

extension TimelineSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        context: AppContext,
        managedObjectContext: NSManagedObjectContext,
        timestampUpdatePublisher: AnyPublisher<Date, Never>,
        timelinePostTableViewCellDelegate: TimelinePostTableViewCellDelegate
    ) -> UITableViewDiffableDataSource<TimelineSection, Item> {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .tweet(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePostTableViewCell.self), for: indexPath) as! TimelinePostTableViewCell
                let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value
                let requestTwitterUserID = activeTwitterAuthenticationBox?.twitterUserID ?? ""
                // configure cell
                managedObjectContext.performAndWait {
                    let tweet = managedObjectContext.object(with: objectID) as! Tweet
                    TimelineSection.configure(cell: cell, readableLayoutFrame: tableView.readableContentGuide.layoutFrame, videoPlaybackService: context.videoPlaybackService, tweet: tweet, requestUserID: requestTwitterUserID)
                    TimelineSection.configure(cell: cell, tweet: tweet, timestampUpdatePublisher: timestampUpdatePublisher)
                }
                cell.delegate = timelinePostTableViewCellDelegate
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.isHidden = false
                cell.activityIndicatorView.startAnimating()
                cell.loadMoreButton.isHidden = true
                return cell
            case .permissionDenied:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePermissionDeniedTableViewCell.self), for: indexPath) as! TimelinePermissionDeniedTableViewCell
                return cell
            default:
                assertionFailure()
                return nil
            }
        }
    }
}

extension TimelineSection {
    private static func configure(
        cell: TimelinePostTableViewCell,
        readableLayoutFrame: CGRect? = nil,
        videoPlaybackService: VideoPlaybackService,
        tweet: Tweet,
        requestUserID: String
    ) {
        // TODO:
        HomeTimelineViewModel.configure(cell: cell, readableLayoutFrame: readableLayoutFrame, videoPlaybackService: videoPlaybackService, tweet: tweet, requestUserID: requestUserID)
    }
    
    private static func configure(
        cell: TimelinePostTableViewCell,
        tweet: Tweet,
        timestampUpdatePublisher: AnyPublisher<Date, Never>
    ) {
        let createdAt = (tweet.retweet ?? tweet).createdAt
        timestampUpdatePublisher
            .sink { _ in
                cell.timelinePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            }
            .store(in: &cell.disposeBag)
        // quote date updater
        let quote = tweet.retweet?.quote ?? tweet.quote
        if let quote = quote {
            let createdAt = quote.createdAt
            timestampUpdatePublisher
                .sink { _ in
                    cell.timelinePostView.quotePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
                }
                .store(in: &cell.disposeBag)
        }
    }
}
