//
//  HomeTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import AlamofireImage
import DateToolsSwift

protocol ContentOffsetAdjustableTimelineViewControllerDelegate: class {
    func navigationBar() -> UINavigationBar
}

final class HomeTimelineViewModel: NSObject {
    
    // input
    let context: AppContext
    let fetchedResultsController: NSFetchedResultsController<TimelineIndex>
    let isFetchingLatestTimeline = CurrentValueSubject<Bool, Never>(false)
    weak var contentOffsetAdjustableTimelineViewControllerDelegate: ContentOffsetAdjustableTimelineViewControllerDelegate?
    weak var tableView: UITableView?
    
    // output
    //var timelineItems: [TimelineItem] = []
    var currentTwitterAuthentication = CurrentValueSubject<TwitterAuthentication?, Never>(nil)
    var diffableDataSource: UITableViewDiffableDataSource<TimelineSection, TimelineItem>?
    
    init(context: AppContext) {
        self.context  = context
        self.fetchedResultsController = {
            let fetchRequest = TimelineIndex.sortedFetchRequest
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchBatchSize = 20
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context.managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            return controller
        }()
        super.init()
        
        fetchedResultsController.delegate = self
    }
    
}

extension HomeTimelineViewModel {

    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .homeTimelineIndex(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: HomeTimelineTableViewCell.self), for: indexPath) as! HomeTimelineTableViewCell
                
                // configure cell
                let managedObjectContext = self.fetchedResultsController.managedObjectContext
                managedObjectContext.performAndWait {
                    let timelineIndex = managedObjectContext.object(with: objectID) as! TimelineIndex
                    HomeTimelineViewModel.configure(cell: cell, timelineIndex: timelineIndex)
                }
                
                return cell
            case .homeTimelineMiddleLoader(let upper):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: HomeTimelineMiddleLoaderCollectionViewCell.self), for: indexPath) as! HomeTimelineMiddleLoaderCollectionViewCell
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: HomeTimelineTableViewCell.self), for: indexPath) as! HomeTimelineTableViewCell
                return cell
            }
        }
    }
    
    static func configure(cell: HomeTimelineTableViewCell, timelineIndex: TimelineIndex) {
        if let tweet = timelineIndex.tweet {
            configure(cell: cell, tweet: tweet)
        }
    }

    private static func configure(cell: HomeTimelineTableViewCell, tweet: Tweet) {
        // set retweet
        cell.retweetNameLabel.text = tweet.retweet == nil ? "" : "Retweet"
        
        // set avatar
        if let avatarImageURL = tweet.user.avatarImageURL() {
            let placeholderImage = UIImage
                .placeholder(size: HomeTimelineTableViewCell.avatarImageViewSize, color: .systemFill)
                .af.imageRoundedIntoCircle()
            let filter = ScaledToSizeCircleFilter(size: HomeTimelineTableViewCell.avatarImageViewSize)
            cell.avatarImageView.af.setImage(
                withURL: avatarImageURL,
                placeholderImage: placeholderImage,
                filter: filter,
                imageTransition: .crossDissolve(0.2)
            )
        } else {
            assertionFailure()
        }

        // set name and username
        cell.nameLabel.text = tweet.user.name
        cell.usernameLabel.text = tweet.user.screenName.flatMap { "@" + $0 }

        // set date
        let createdAt = tweet.createdAt
        cell.dateLabel.text = createdAt.shortTimeAgoSinceNow
        cell.dateLabelUpdateSubscription = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .sink { _ in
                // do not use core date entity in this run loop
                cell.dateLabel.text = createdAt.shortTimeAgoSinceNow
            }
        
        // set text
        cell.textlabel.text = tweet.text
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension HomeTimelineViewModel: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        guard let tableView = self.tableView else { fatalError() }
        guard let navigationBar = self.contentOffsetAdjustableTimelineViewControllerDelegate?.navigationBar() else { fatalError() }
        
        guard let diffableDataSource = self.diffableDataSource else { return }
        let oldSnapshot = diffableDataSource.snapshot()
        let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        
        var newSnapshot = NSDiffableDataSourceSnapshot<TimelineSection, TimelineItem>()
        newSnapshot.appendSections([.main])

        let managedObjectContext = fetchedResultsController.managedObjectContext
        managedObjectContext.performAndWait {
            //var items: [TimelineItem] = []
            for (i, objectID) in snapshot.itemIdentifiers.enumerated() {
                // save into buffer
                newSnapshot.appendItems([.homeTimelineIndex(objectID)], toSection: .main)
                //items.append(.homeTimelineIndex(objectID))

                let timelineIndex = managedObjectContext.object(with: objectID) as! TimelineIndex
                if let tweet = timelineIndex.tweet {
                    if tweet.hasMore {
                        let isLast = i == snapshot.itemIdentifiers.count - 1
                        if isLast {
                            newSnapshot.appendItems([.bottomLoader], toSection: .main)
                            //items.append(.bottomLoader)
                        } else {
                            newSnapshot.appendItems([.homeTimelineMiddleLoader(upper: tweet.tweetID)], toSection: .main)
                            //items.append(.homeTimelineMiddleLoader(upper: tweet.tweetID))
                        }
                    } else {
                        // do nothing
                    }
                }
            }   // end for
        }   // end performAndWait

        guard let difference = calculateReloadSnapshotDifference(navigationBar: navigationBar, tableView: tableView, oldSnapshot: oldSnapshot, newSnapshot: newSnapshot) else {
            diffableDataSource.apply(newSnapshot)
            return
        }
        
        diffableDataSource.apply(newSnapshot, animatingDifferences: false) {
            tableView.scrollToRow(at: difference.targetIndexPath, at: .top, animated: false)
            tableView.contentOffset.y = tableView.contentOffset.y - difference.offset
        }
    }
    
    private struct Difference<T> {
        let item: T
        let sourceIndexPath: IndexPath
        let targetIndexPath: IndexPath
        let offset: CGFloat
    }

    private func calculateReloadSnapshotDifference<T: Hashable>(
        navigationBar: UINavigationBar,
        tableView: UITableView,
        oldSnapshot: NSDiffableDataSourceSnapshot<TimelineSection, T>,
        newSnapshot: NSDiffableDataSourceSnapshot<TimelineSection, T>
    ) -> Difference<T>? {
        guard oldSnapshot.numberOfItems != 0 else { return nil }
        
        // old snapshot not empty. set source index path to first item if not match
        let sourceIndexPath = HomeTimelineViewModel.topVisibleTableViewCellIndexPath(in: tableView, navigationBar: navigationBar) ?? IndexPath(row: 0, section: 0)
        
        guard sourceIndexPath.row < oldSnapshot.itemIdentifiers(inSection: .main).count else { return nil }
        
        let timelineItem = oldSnapshot.itemIdentifiers(inSection: .main)[sourceIndexPath.row]
        guard let itemIndex = newSnapshot.itemIdentifiers(inSection: .main).firstIndex(of: timelineItem) else { return nil }
        let targetIndexPath = IndexPath(row: itemIndex, section: 0)
        
        let offset = HomeTimelineViewModel.tableViewCellOriginOffsetToWindowTop(in: tableView, at: sourceIndexPath, navigationBar: navigationBar)
        return Difference(
            item: timelineItem,
            sourceIndexPath: sourceIndexPath,
            targetIndexPath: targetIndexPath,
            offset: offset
        )
    }
    
    /// https://bluelemonbits.com/2018/08/26/inserting-cells-at-the-top-of-a-uitableview-with-no-scrolling/
    static func topVisibleTableViewCellIndexPath(in tableView: UITableView, navigationBar: UINavigationBar) -> IndexPath? {
        let navigationBarRectInTableView = tableView.convert(navigationBar.bounds, from: navigationBar)
        let navigationBarMaxYPosition = CGPoint(x: 0, y: navigationBarRectInTableView.origin.y + navigationBarRectInTableView.size.height + 1)
        let mostTopVisiableIndexPath = tableView.indexPathForRow(at: navigationBarMaxYPosition)
        return mostTopVisiableIndexPath
    }
    
    static func tableViewCellOriginOffsetToWindowTop(in tableView: UITableView, at indexPath: IndexPath, navigationBar: UINavigationBar) -> CGFloat {
        let rectForTopRow = tableView.rectForRow(at: indexPath)
        let navigationBarRectInTableView = tableView.convert(navigationBar.bounds, from: navigationBar)
        let navigationBarMaxYPosition = CGPoint(x: 0, y: navigationBarRectInTableView.origin.y + navigationBarRectInTableView.size.height + 1)
        let differenceBetweenTopRowAndNavigationBar = rectForTopRow.origin.y - navigationBarMaxYPosition.y
        return differenceBetweenTopRowAndNavigationBar
    }
    
}
