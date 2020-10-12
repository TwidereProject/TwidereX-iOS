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
    weak var timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate?
    
    // output
    // top loader
    private(set) lazy var loadLatestStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            LoadLatestState.Initial(viewModel: self),
            LoadLatestState.Loading(viewModel: self),
            LoadLatestState.Fail(viewModel: self),
            LoadLatestState.Idle(viewModel: self),
        ])
        stateMachine.enter(LoadLatestState.Initial.self)
        return stateMachine
    }()
    lazy var loadLatestStateMachinePublisher = CurrentValueSubject<LoadLatestState, Never>(LoadLatestState.Initial(viewModel: self))
    // bottom loader
    private(set) lazy var loadoldestStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            LoadOldestState.Initial(viewModel: self),
            LoadOldestState.Loading(viewModel: self),
            LoadOldestState.Fail(viewModel: self),
            LoadOldestState.Idle(viewModel: self),
            LoadOldestState.NoMore(viewModel: self),
        ])
        stateMachine.enter(LoadOldestState.Initial.self)
        return stateMachine
    }()
    lazy var loadOldestStateMachinePublisher = CurrentValueSubject<LoadOldestState, Never>(LoadOldestState.Initial(viewModel: self))
    // middle loader
    let loadMiddleSateMachineList = CurrentValueSubject<[Tweet.TweetID: GKStateMachine], Never>([:])
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
                self.loadMiddleSateMachineList
                    .receive(on: DispatchQueue.main)
                    .sink { ids in
                        if let stateMachine = ids[upper] {
                            guard let state = stateMachine.currentState else {
                                assertionFailure()
                                return
                            }
                            
                            let isLoading = state is LoadMiddleState.Loading
                            cell.loadMoreButton.isHidden = isLoading
                            if isLoading {
                                cell.activityIndicatorView.startAnimating()
                            } else {
                                cell.activityIndicatorView.stopAnimating()
                            }
                        } else {
                            cell.loadMoreButton.isHidden = false
                            cell.activityIndicatorView.stopAnimating()
                        }
                    }
                    .store(in: &cell.disposeBag)
                var dict = self.loadMiddleSateMachineList.value
                if let _ = dict[upper] {
                    // do nothing
                } else {
                    let stateMachine = GKStateMachine(states: [
                        LoadMiddleState.Initial(viewModel: self, anchorTweetID: upper),
                        LoadMiddleState.Loading(viewModel: self, anchorTweetID: upper),
                        LoadMiddleState.Fail(viewModel: self, anchorTweetID: upper),
                        LoadMiddleState.Success(viewModel: self, anchorTweetID: upper),
                    ])
                    stateMachine.enter(LoadMiddleState.Initial.self)
                    dict[upper] = stateMachine
                    self.loadMiddleSateMachineList.value = dict
                }
                cell.delegate = self.timelineMiddleLoaderTableViewCellDelegate
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
            configure(cell: cell, tweet: tweet)
            internalConfigure(cell: cell, tweet: tweet, attribute: attribute)
        }
    }

    static func configure(cell: TimelinePostTableViewCell, tweet: Tweet) {
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

            // set text
            cell.timelinePostView.quotePostView.activeTextLabel.text = quote.text
        }
        cell.timelinePostView.quotePostView.isHidden = quote == nil
    }
    
    private static func internalConfigure(cell: TimelinePostTableViewCell, tweet: Tweet, attribute: TimelineItem.Attribute) {
        // tweet date updater
        let createdAt = (tweet.retweet ?? tweet).createdAt
        NotificationCenter.default.publisher(for: HomeTimelineViewModel.secondStepTimerTriggered, object: nil)
            .sink { _ in
                cell.timelinePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            }
            .store(in: &cell.disposeBag)
        
        // quote date updater
        let quote = tweet.retweet?.quote ?? tweet.quote
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
        switch attribute.separatorLineStyle {
        case .indent:
            cell.separatorLineExpandLeadingLayoutConstraint.isActive = false
            cell.separatorLineNormalLeadingLayoutConstraint.isActive = false
            cell.separatorLineExpandTrailingLayoutConstraint.isActive = false
            cell.separatorLineIndentLeadingLayoutConstraint.isActive = true
            cell.separatorLineNormalTrailingLayoutConstraint.isActive = true
        case .expand:
            cell.separatorLineNormalLeadingLayoutConstraint.isActive = false
            cell.separatorLineIndentLeadingLayoutConstraint.isActive = false
            cell.separatorLineNormalTrailingLayoutConstraint.isActive = false
            cell.separatorLineExpandLeadingLayoutConstraint.isActive = true
            cell.separatorLineExpandTrailingLayoutConstraint.isActive = true
        case .normal:
            cell.separatorLineExpandLeadingLayoutConstraint.isActive = false
            cell.separatorLineExpandTrailingLayoutConstraint.isActive = false
            cell.separatorLineIndentLeadingLayoutConstraint.isActive = false
            cell.separatorLineNormalLeadingLayoutConstraint.isActive = true
            cell.separatorLineNormalTrailingLayoutConstraint.isActive = true
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
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

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
            var shouldAddBottomLoader = false
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
                    let isLast = i == snapshot.itemIdentifiers.count - 1
                    switch (isLast, tweet.hasMore) {
                    case (true, false):
                        attribute.separatorLineStyle = .normal
                    case (false, true):
                        attribute.separatorLineStyle = .expand
                        newSnapshot.appendItems([.homeTimelineMiddleLoader(upper: tweet.idStr)], toSection: .main)
                    case (true, true):
                        attribute.separatorLineStyle = .normal
                        shouldAddBottomLoader = true
                    case (false, false):
                        attribute.separatorLineStyle = .indent
                    }
                }
            }   // end for
            let endSnapshot = CACurrentMediaTime()
            os_log("%{public}s[%{public}ld], %{public}s: calculate home timeline snapshot cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, endSnapshot - start)
            
            DispatchQueue.main.async {
                if shouldAddBottomLoader, !(self.loadoldestStateMachine.currentState is LoadOldestState.NoMore) {
                    newSnapshot.appendItems([.bottomLoader], toSection: .main)
                }
                
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
