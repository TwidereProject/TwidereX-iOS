//
//  HomeTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import os.log
import func AVFoundation.AVMakeRect
import UIKit
import GameplayKit
import Combine
import CoreData
import CoreDataStack
import AlamofireImage
import DateToolsSwift

protocol ContentOffsetAdjustableTimelineViewControllerDelegate: class {
    func navigationBar() -> UINavigationBar
}

final class HomeTimelineViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let fetchedResultsController: NSFetchedResultsController<TimelineIndex>
    let currentTwitterAuthentication = CurrentValueSubject<TwitterAuthentication?, Never>(nil)
    let isFetchingLatestTimeline = CurrentValueSubject<Bool, Never>(false)
    weak var contentOffsetAdjustableTimelineViewControllerDelegate: ContentOffsetAdjustableTimelineViewControllerDelegate?
    weak var tableView: UITableView?
    weak var timelinePostTableViewCellDelegate: TimelinePostTableViewCellDelegate?
    
    // output
    private(set) lazy var stateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Reloading(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.LoadingMore(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    lazy var stateMachinePublisher = CurrentValueSubject<State, Never>(State.Initial(viewModel: self))
    var diffableDataSource: UITableViewDiffableDataSource<TimelineSection, TimelineItem>?
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
        diffableDataSource = UITableViewDiffableDataSource<TimelineSection, TimelineItem>(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
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
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.isHidden = false
                cell.activityIndicatorView.startAnimating()
                return cell
            default:
                return nil
            }
        }
    }
    
    static func configure(cell: TimelinePostTableViewCell, timelineIndex: TimelineIndex, attribute: TimelineItem.Attribute) {
        if let tweet = timelineIndex.tweet {
            configure(cell: cell, tweetInterface: tweet)
            internalConfigure(cell: cell, tweet: tweet, attribute: attribute)
        }
    }

    static func configure(cell: TimelinePostTableViewCell, tweetInterface tweet: TweetInterface) {
        // set retweet display
        cell.timelinePostView.retweetContainerStackView.isHidden = tweet.retweetObject == nil
        cell.timelinePostView.retweetInfoLabel.text = tweet.userObject.name.flatMap { $0 + " Retweeted" } ?? " "

        // set avatar
        if let avatarImageURL = (tweet.retweetObject?.userObject ?? tweet.userObject).avatarImageURL() {
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
        cell.timelinePostView.nameLabel.text = (tweet.retweetObject?.userObject ?? tweet.userObject).name
        cell.timelinePostView.usernameLabel.text = (tweet.retweetObject?.userObject ?? tweet.userObject).screenName.flatMap { "@" + $0 }

        // set date
        let createdAt = (tweet.retweetObject ?? tweet).createdAt
        cell.timelinePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
        
        // set text
        cell.timelinePostView.activeTextLabel.text = (tweet.retweetObject ?? tweet).text

        // set action toolbar title
        let retweetCountTitle: String = {
            let count = (tweet.retweetObject ?? tweet).retweetCountInt
            return HomeTimelineViewModel.formattedNumberTitleForActionButton(count)
        }()
        cell.timelinePostView.actionToolbar.retweetButton.setTitle(retweetCountTitle, for: .normal)

        let favoriteCountTitle: String = {
            let count = (tweet.retweetObject ?? tweet).favoriteCountInt
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

        let maxSize: CGSize = {
            // auto layout first time fallback
            if cell.timelinePostView.frame == .zero {
                let bounds = UIScreen.main.bounds
                let maxWidth = min(bounds.width, bounds.height)
                return CGSize(
                    width: maxWidth,
                    height: maxWidth * 0.3
                )
            }
            let maxWidth: CGFloat = {
                // use timelinePostView width as container width
                // that width follows readable width and keep constant width after rotate
                var containerWidth = cell.timelinePostView.frame.width
                containerWidth -= 10
                containerWidth -= TimelinePostView.avatarImageViewSize.width
                return containerWidth
            }()
            return CGSize(width: maxWidth, height: maxWidth * 0.6)
        }()
        if mosaicMetas.count == 1 {
            let meta = mosaicMetas[0]
            let imageView = cell.timelinePostView.mosaicImageView.setupImageView(aspectRatio: meta.size, maxSize: maxSize)
            imageView.af.setImage(
                withURL: meta.url,
                placeholderImage: UIImage.placeholder(color: .systemFill),
                imageTransition: .crossDissolve(0.2)
            )
        } else {
            let imageViews = cell.timelinePostView.mosaicImageView.setupImageViews(count: mosaicMetas.count, maxHeight: maxSize.height)
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
        let quote = tweet.retweetObject?.quoteObject ?? tweet.quoteObject
        if let quote = quote {
            // set avatar
            if let avatarImageURL = quote.userObject.avatarImageURL() {
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
            cell.timelinePostView.quotePostView.nameLabel.text = quote.userObject.name
            cell.timelinePostView.quotePostView.usernameLabel.text = quote.userObject.screenName.flatMap { "@" + $0 }

            // set date
            let createdAt = quote.createdAt
            cell.timelinePostView.quotePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow

            // set text
            cell.timelinePostView.quotePostView.activeTextLabel.text = quote.text
        }
        cell.timelinePostView.quotePostView.isHidden = quote == nil
    }
    
    private static func internalConfigure(cell: TimelinePostTableViewCell, tweet: TweetInterface, attribute: TimelineItem.Attribute) {
        // tweet date updater
        let createdAt = (tweet.retweetObject ?? tweet).createdAt
        NotificationCenter.default.publisher(for: HomeTimelineViewModel.secondStepTimerTriggered, object: nil)
            .sink { _ in
                cell.timelinePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            }
            .store(in: &cell.disposeBag)
        
        // quote date updater
        let quote = tweet.retweetObject?.quoteObject ?? tweet.quoteObject
        if let quote = quote {
            let createdAt = quote.createdAt
            cell.timelinePostView.quotePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            NotificationCenter.default.publisher(for: HomeTimelineViewModel.secondStepTimerTriggered, object: nil)
                .sink { _ in
                    cell.timelinePostView.quotePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
                }
                .store(in: &cell.disposeBag)
        }
        

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

        let parentManagedObjectContext = fetchedResultsController.managedObjectContext
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.parent = parentManagedObjectContext
        
        managedObjectContext.perform {
            let start = CACurrentMediaTime()
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
            let endSnapshot = CACurrentMediaTime()
            os_log("%{public}s[%{public}ld], %{public}s: calculate home timeline snapshot cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, endSnapshot - start)
            
            DispatchQueue.main.async {
                guard let difference = self.calculateReloadSnapshotDifference(navigationBar: navigationBar, tableView: tableView, oldSnapshot: oldSnapshot, newSnapshot: newSnapshot) else {
                    diffableDataSource.apply(newSnapshot)
                    return
                }
                
                diffableDataSource.apply(newSnapshot, animatingDifferences: false) {
                    tableView.scrollToRow(at: difference.targetIndexPath, at: .top, animated: false)
                    tableView.contentOffset.y = tableView.contentOffset.y - difference.offset
                    self.isFetchingLatestTimeline.value = false
                }
                
                let end = CACurrentMediaTime()
                os_log("%{public}s[%{public}ld], %{public}s: calculate home timeline layout cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - endSnapshot)
            }
        }   // end perform
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
    private static let secondStepTimerTriggered = Notification.Name("com.twidere.twiderex.home-timeline.second-step-timer-triggered")
}
