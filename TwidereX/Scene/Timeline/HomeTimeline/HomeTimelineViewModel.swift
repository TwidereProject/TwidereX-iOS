//
//  HomeTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import os.log
import func AVFoundation.AVMakeRect
import UIKit
import Combine
import CoreData
import CoreDataStack
import AlamofireImage
import DateToolsSwift

protocol ContentOffsetAdjustableTimelineViewControllerDelegate: class {
    func navigationBar() -> UINavigationBar
}

final class SwipeEnabledDiffableDataSource: UITableViewDiffableDataSource<TimelineSection, TimelineItem> {
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

final class HomeTimelineViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let fetchedResultsController: NSFetchedResultsController<TimelineIndex>
    let isFetchingLatestTimeline = CurrentValueSubject<Bool, Never>(false)
    weak var contentOffsetAdjustableTimelineViewControllerDelegate: ContentOffsetAdjustableTimelineViewControllerDelegate?
    weak var tableView: UITableView?
    weak var timelinePostTableViewCellDelegate: TimelinePostTableViewCellDelegate?
    
    // output
    var currentTwitterAuthentication = CurrentValueSubject<TwitterAuthentication?, Never>(nil)
    var diffableDataSource: SwipeEnabledDiffableDataSource?
    var cellFrameCache = NSCache<NSNumber, NSValue>()
    
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
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                NotificationCenter.default.post(name: HomeTimelineViewModel.secondStepTimerTriggered, object: nil)
            }
            .store(in: &disposeBag)
    }
    
}

extension HomeTimelineViewModel {

    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = SwipeEnabledDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .homeTimelineIndex(let objectID, let expandStatus):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePostTableViewCell.self), for: indexPath) as! TimelinePostTableViewCell
                
                // configure cell
                let managedObjectContext = self.fetchedResultsController.managedObjectContext
                managedObjectContext.performAndWait {
                    let timelineIndex = managedObjectContext.object(with: objectID) as! TimelineIndex
                    HomeTimelineViewModel.configure(cell: cell, timelineIndex: timelineIndex, attribute: expandStatus)
                }
                cell.delegate = self.timelinePostTableViewCellDelegate
                return cell
            case .homeTimelineMiddleLoader(let upper):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self), for: indexPath) as! TimelineMiddleLoaderTableViewCell
                return cell
            case .bottomLoader:
                // TODO:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                return cell
            }
        }
    }
    
    static func configure(cell: TimelinePostTableViewCell, timelineIndex: TimelineIndex, attribute: TimelineItem.Attribute) {
        if let tweet = timelineIndex.tweet {
            configure(cell: cell, tweet: tweet, attribute: attribute)
        }
    }

    private static func configure(cell: TimelinePostTableViewCell, tweet: Tweet, attribute: TimelineItem.Attribute) {
        // set retweet display
        cell.timelinePostView.retweetContainerStackView.isHidden = tweet.retweet == nil
        cell.timelinePostView.retweetInfoLabel.text = tweet.user.name.flatMap { $0 + " Retweeted" } ?? " "

        // set avatar
        if let avatarImageURL = (tweet.retweet?.user ?? tweet.user).avatarImageURL() {
            let placeholderImage = UIImage
                .placeholder(size: TimelinePostView.avatarImageViewSize, color: .systemFill)
                .af.imageRoundedIntoCircle()
            let filter = ScaledToSizeCircleFilter(size: TimelinePostView.avatarImageViewSize)
            cell.timelinePostView.avatarImageView.af.setImage(
                withURL: avatarImageURL,
                placeholderImage: placeholderImage,
                filter: filter,
                imageTransition: .crossDissolve(0.2)
            )
        } else {
            assertionFailure()
        }

        // set name and username
        cell.timelinePostView.nameLabel.text = (tweet.retweet?.user ?? tweet.user).name
        cell.timelinePostView.usernameLabel.text = (tweet.retweet?.user ?? tweet.user).screenName.flatMap { "@" + $0 }

        // set date
        let createdAt = (tweet.retweet ?? tweet).createdAt
        cell.timelinePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
        NotificationCenter.default.publisher(for: HomeTimelineViewModel.secondStepTimerTriggered, object: nil)
            .sink { _ in
                cell.timelinePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            }
            .store(in: &cell.disposeBag)
        
        // set text
        cell.timelinePostView.activeTextLabel.text = (tweet.retweet ?? tweet).text

        // set action toolbar title
        let retweetCountTitle: String = {
            let count = (tweet.retweet ?? tweet).retweetCount.flatMap { Int(truncating: $0) }
            return HomeTimelineViewModel.formattedNumberTitleForActionButton(count)
        }()
        cell.timelinePostView.actionToolbar.retweetButton.setTitle(retweetCountTitle, for: .normal)

        let favoriteCountTitle: String = {
            let count = (tweet.retweet ?? tweet).favoriteCount.flatMap { Int(truncating: $0) }
            return HomeTimelineViewModel.formattedNumberTitleForActionButton(count)
        }()
        cell.timelinePostView.actionToolbar.favoriteButton.setTitle(favoriteCountTitle, for: .normal)

        // set image display
        let media = tweet.extendedEntities?.media ?? []
        var mosaicMetas: [MosaicMeta] = []
        for element in media {
            guard let (url, size) = element.photoURL(sizeKind: .small) else { continue }
            let meta = MosaicMeta(url: url, size: size)
            mosaicMetas.append(meta)
        }
        let maxWidth: CGFloat = {
            var containerWidth = cell.frame.width - 16 * 2  // layout margin
            containerWidth -= 10
            containerWidth -= TimelinePostView.avatarImageViewSize.width
            return containerWidth
        }()
        let maxSize = CGSize(width: maxWidth, height: cell.bounds.width * 0.6)
        if mosaicMetas.count == 1 {
            let meta = mosaicMetas[0]
            let imageView = cell.timelinePostView.mosaicImageView.setupImageView(aspectRatio: meta.size, maxSize: maxSize)
            imageView.af.setImage(
                withURL: meta.url,
                placeholderImage: UIImage.placeholder(color: .systemFill),
                imageTransition: .crossDissolve(0.2)
            )
        } else {
            let imageViews = cell.timelinePostView.mosaicImageView.setupImageViews(count: mosaicMetas.count, maxHeight: cell.bounds.width * 0.5)
            for (i, imageView) in imageViews.enumerated() {
                let meta = mosaicMetas[i]
                imageView.af.setImage(
                    withURL: meta.url,
                    placeholderImage: UIImage.placeholder(color: .systemFill),
                    imageTransition: .crossDissolve(0.2)
                )
            }
        }
        cell.timelinePostView.mosaicImageView.isHidden = mosaicMetas.isEmpty

        // set quote display
        let quote = tweet.retweet?.quote ?? tweet.quote
        if let quote = quote {
            // set avatar
            if let avatarImageURL = quote.user.avatarImageURL() {
                let placeholderImage = UIImage
                    .placeholder(size: TimelinePostView.avatarImageViewSize, color: .systemFill)
                    .af.imageRoundedIntoCircle()
                let filter = ScaledToSizeCircleFilter(size: TimelinePostView.avatarImageViewSize)
                cell.timelinePostView.quotePostView.avatarImageView.af.setImage(
                    withURL: avatarImageURL,
                    placeholderImage: placeholderImage,
                    filter: filter,
                    imageTransition: .crossDissolve(0.2)
                )
            } else {
                assertionFailure()
            }

            // set name and username
            cell.timelinePostView.quotePostView.nameLabel.text = quote.user.name
            cell.timelinePostView.quotePostView.usernameLabel.text = quote.user.screenName.flatMap { "@" + $0 }

            // set date
            let createdAt = quote.createdAt
            cell.timelinePostView.quotePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            NotificationCenter.default.publisher(for: HomeTimelineViewModel.secondStepTimerTriggered, object: nil)
                .sink { _ in
                    cell.timelinePostView.quotePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
                }
                .store(in: &cell.disposeBag)

            // set text
            cell.timelinePostView.quotePostView.activeTextLabel.text = quote.text
        }
        cell.timelinePostView.quotePostView.isHidden = quote == nil
        
        // set separator line indent in non-conflict order
        if attribute.indentSeparatorLine {
            cell.separatorLineLeadingLayoutConstraint.isActive = false
            cell.separatorLineIndentLeadingLayoutConstraint.isActive = true
        } else {
            cell.separatorLineIndentLeadingLayoutConstraint.isActive = false
            cell.separatorLineLeadingLayoutConstraint.isActive = true
        }
    }
    
    struct MosaicMeta {
        let url: URL
        let size: CGSize
    }

    static func formattedNumberTitleForActionButton(_ number: Int?) -> String {
        guard let number = number, number > 0 else {
            return ""
        }

        return String(number)
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
            for (i, objectID) in snapshot.itemIdentifiers.enumerated() {
                let attribute: TimelineItem.Attribute = {
                    for item in oldSnapshot.itemIdentifiers {
                        guard case let .homeTimelineIndex(oldObjectID, attribute) = item else { continue }
                        guard objectID == oldObjectID else { continue }
                        return attribute
                    }
                    
                    return TimelineItem.Attribute()
                }()
                
                // save into buffer
                newSnapshot.appendItems([.homeTimelineIndex(objectID: objectID, attribute: attribute)], toSection: .main)

                let timelineIndex = managedObjectContext.object(with: objectID) as! TimelineIndex
                if let tweet = timelineIndex.tweet {
                    attribute.indentSeparatorLine = !tweet.hasMore
                    
                    if tweet.hasMore {
                        let isLast = i == snapshot.itemIdentifiers.count - 1
                        if isLast {
                            newSnapshot.appendItems([.bottomLoader], toSection: .main)
                        } else {
                            newSnapshot.appendItems([.homeTimelineMiddleLoader(upper: tweet.tweetID)], toSection: .main)
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

extension HomeTimelineViewModel {
    static let secondStepTimerTriggered = Notification.Name("com.twidere.twiderex.home-timeline.second-step-timer-triggered")
}
