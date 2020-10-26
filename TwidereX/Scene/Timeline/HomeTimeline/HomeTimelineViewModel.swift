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

final class HomeTimelineViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let fetchedResultsController: NSFetchedResultsController<TimelineIndex>
    let currentTwitterAuthentication = CurrentValueSubject<TwitterAuthentication?, Never>(nil)
    let currentTwitterUser = CurrentValueSubject<TwitterUser?, Never>(nil)
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
    lazy var loadLatestStateMachinePublisher = CurrentValueSubject<LoadLatestState?, Never>(nil)
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
    lazy var loadOldestStateMachinePublisher = CurrentValueSubject<LoadOldestState?, Never>(nil)
    // middle loader
    let loadMiddleSateMachineList = CurrentValueSubject<[NSManagedObjectID: GKStateMachine], Never>([:])    // TimelineIndex.objectID : middle loading state machine
    var diffableDataSource: UITableViewDiffableDataSource<TimelineSection, TimelineItem>?
    var cellFrameCache = NSCache<NSNumber, NSValue>()
    
    init(context: AppContext) {
        self.context  = context
        self.fetchedResultsController = {
            let fetchRequest = TimelineIndex.sortedFetchRequest
            fetchRequest.fetchBatchSize = 20
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.relationshipKeyPathsForPrefetching = [#keyPath(TimelineIndex.tweet)]
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
            case .homeTimelineMiddleLoader(let upperTimelineIndexObjectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self), for: indexPath) as! TimelineMiddleLoaderTableViewCell
                self.loadMiddleSateMachineList
                    .receive(on: DispatchQueue.main)
                    .sink { ids in
                        if let stateMachine = ids[upperTimelineIndexObjectID] {
                            guard let state = stateMachine.currentState else {
                                assertionFailure()
                                return
                            }
                            
                            // make success state same as loading due to snapshot updating delay
                            let isLoading = state is LoadMiddleState.Loading || state is LoadMiddleState.Success    
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
                if let _ = dict[upperTimelineIndexObjectID] {
                    // do nothing
                } else {
                    let stateMachine = GKStateMachine(states: [
                        LoadMiddleState.Initial(viewModel: self, upperTimelineIndexObjectID: upperTimelineIndexObjectID),
                        LoadMiddleState.Loading(viewModel: self, upperTimelineIndexObjectID: upperTimelineIndexObjectID),
                        LoadMiddleState.Fail(viewModel: self, upperTimelineIndexObjectID: upperTimelineIndexObjectID),
                        LoadMiddleState.Success(viewModel: self, upperTimelineIndexObjectID: upperTimelineIndexObjectID),
                    ])
                    stateMachine.enter(LoadMiddleState.Initial.self)
                    dict[upperTimelineIndexObjectID] = stateMachine
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
            configure(cell: cell, tweet: tweet, requestUserID: timelineIndex.userID)
            internalConfigure(cell: cell, tweet: tweet, attribute: attribute)
        }
    }

    static func configure(cell: TimelinePostTableViewCell, tweet: Tweet, requestUserID: String) {
        // set retweet display
        cell.timelinePostView.retweetContainerStackView.isHidden = tweet.retweet == nil
        cell.timelinePostView.retweetInfoLabel.text = tweet.author.name + " Retweeted"

        // set avatar
        if let avatarImageURL = (tweet.retweet?.author ?? tweet.author).avatarImageURL() {
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
        
        cell.timelinePostView.lockImageView.isHidden = !((tweet.retweet?.author ?? tweet.author).protected)

        // set name and username
        cell.timelinePostView.nameLabel.text = (tweet.retweet?.author ?? tweet.author).name
        cell.timelinePostView.usernameLabel.text = "@" + (tweet.retweet?.author ?? tweet.author).username

        // set date
        let createdAt = (tweet.retweet ?? tweet).createdAt
        cell.timelinePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
        
        // set text
        cell.timelinePostView.activeTextLabel.text = (tweet.retweet ?? tweet).text

        // set action toolbar title
        let isRetweeted = (tweet.retweet ?? tweet).retweetBy.flatMap({ $0.contains(where: { $0.id == requestUserID }) }) ?? false
        let retweetCountTitle: String = {
            let count = (tweet.retweet ?? tweet).metrics?.retweetCount.flatMap { Int(truncating: $0) }
            return HomeTimelineViewModel.formattedNumberTitleForActionButton(count)
        }()
        let retweetButtonTintColor = isRetweeted ? Asset.Colors.hightLight.color : .secondaryLabel
        cell.timelinePostView.actionToolbar.retweetButton.tintColor = retweetButtonTintColor
        cell.timelinePostView.actionToolbar.retweetButton.setTitle(retweetCountTitle, for: .normal)
        cell.timelinePostView.actionToolbar.retweetButton.setTitleColor(retweetButtonTintColor, for: .normal)
        cell.timelinePostView.actionToolbar.retweetButton.setTitleColor(retweetButtonTintColor.withAlphaComponent(0.8), for: .highlighted)
        cell.timelinePostView.actionToolbar.retweetButton.isEnabled = !(tweet.retweet ?? tweet).author.protected

        let isLike = (tweet.retweet ?? tweet).likeBy.flatMap({ $0.contains(where: { $0.id == requestUserID }) }) ?? false
        let favoriteCountTitle: String = {
            let count = (tweet.retweet ?? tweet).metrics?.likeCount.flatMap { Int(truncating: $0) }
            return HomeTimelineViewModel.formattedNumberTitleForActionButton(count)
        }()
        let likeButtonImage = isLike ? Asset.Health.heartFill.image.withRenderingMode(.alwaysTemplate) :
            Asset.Health.heart.image.withRenderingMode(.alwaysTemplate)
        let likeButtonTintColor = isLike ? Asset.Colors.heartPink.color : .secondaryLabel
        cell.timelinePostView.actionToolbar.favoriteButton.tintColor = likeButtonTintColor
        cell.timelinePostView.actionToolbar.favoriteButton.setImage(likeButtonImage, for: .normal)
        cell.timelinePostView.actionToolbar.favoriteButton.setTitle(favoriteCountTitle, for: .normal)
        cell.timelinePostView.actionToolbar.favoriteButton.setTitleColor(likeButtonTintColor, for: .normal)
        cell.timelinePostView.actionToolbar.favoriteButton.setTitleColor(likeButtonTintColor.withAlphaComponent(0.8), for: .highlighted)

        // set image display
        let media = Array(tweet.media ?? []).sorted { $0.index.compare($1.index) == .orderedAscending }
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
            if let avatarImageURL = quote.author.avatarImageURL() {
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
            
            // Note: cannot quote protected user
            cell.timelinePostView.quotePostView.lockImageView.isHidden = !quote.author.protected

            // set name and username
            cell.timelinePostView.quotePostView.nameLabel.text = quote.author.name
            cell.timelinePostView.quotePostView.usernameLabel.text = "@" + quote.author.username

            // set date
            let createdAt = quote.createdAt
            cell.timelinePostView.quotePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow

            // set text
            cell.timelinePostView.quotePostView.activeTextLabel.text = quote.text
        }
        cell.timelinePostView.quotePostView.isHidden = quote == nil
        
        // observe model change
        ManagedObjectObserver.observe(object: tweet.retweet ?? tweet)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // do nothing
            } receiveValue: { change in
                guard case let .update(object) = change.changeType,
                      let newTweet = object as? Tweet else { return }
                let targetTweet = newTweet.retweet ?? newTweet
                
                let retweetCount = targetTweet.metrics?.retweetCount.flatMap { Int(truncating: $0) }
                let retweetCountTitle = HomeTimelineViewModel.formattedNumberTitleForActionButton(retweetCount)
                cell.timelinePostView.actionToolbar.retweetButton.setTitle(retweetCountTitle, for: .normal)
                os_log("%{public}s[%{public}ld], %{public}s: retweet count label for tweet %s did update: %ld", ((#file as NSString).lastPathComponent), #line, #function, targetTweet.id, retweetCount ?? 0)
                
                let favoriteCount = targetTweet.metrics?.likeCount.flatMap { Int(truncating: $0) }
                let favoriteCountTitle = HomeTimelineViewModel.formattedNumberTitleForActionButton(favoriteCount)
                cell.timelinePostView.actionToolbar.favoriteButton.setTitle(favoriteCountTitle, for: .normal)
                os_log("%{public}s[%{public}ld], %{public}s: like count label for tweet %s did update: %ld", ((#file as NSString).lastPathComponent), #line, #function, targetTweet.id, favoriteCount ?? 0)
            }
            .store(in: &cell.disposeBag)

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

        let parentManagedObjectContext = fetchedResultsController.managedObjectContext
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.parent = parentManagedObjectContext
        
        managedObjectContext.perform {
            let start = CACurrentMediaTime()
            var shouldAddBottomLoader = false
            
            let timelineIndexes: [TimelineIndex] = {
                let request = TimelineIndex.sortedFetchRequest
                request.returnsObjectsAsFaults = false
                do {
                    return try managedObjectContext.fetch(request)
                } catch {
                    assertionFailure(error.localizedDescription)
                    return []
                }
            }()
            
            let endFetch = CACurrentMediaTime()
            os_log("%{public}s[%{public}ld], %{public}s: fetch timelineIndexes cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, endFetch - start)
            
            var oldSnapshotAttributeDict: [NSManagedObjectID : TimelineItem.Attribute] = [:]
            for item in oldSnapshot.itemIdentifiers {
                guard case let .homeTimelineIndex(objectID, attribute) = item else { continue }
                oldSnapshotAttributeDict[objectID] = attribute
            }
            let endPrepareCache = CACurrentMediaTime()
            
            var newTimelineItems: [TimelineItem] = []
            os_log("%{public}s[%{public}ld], %{public}s: prepare timelineIndex cache cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, endPrepareCache - endFetch)
            for (i, timelineIndex) in timelineIndexes.enumerated() {
                let attribute = oldSnapshotAttributeDict[timelineIndex.objectID] ?? TimelineItem.Attribute()

                // append new item into snapshot
                newTimelineItems.append(.homeTimelineIndex(objectID: timelineIndex.objectID, attribute: attribute))
                
                let isLast = i == timelineIndexes.count - 1
                switch (isLast, timelineIndex.hasMore) {
                case (true, false):
                    attribute.separatorLineStyle = .normal
                case (false, true):
                    attribute.separatorLineStyle = .expand
                    newTimelineItems.append(.homeTimelineMiddleLoader(upperTimelineIndexAnchorObjectID: timelineIndex.objectID))
                case (true, true):
                    attribute.separatorLineStyle = .normal
                    shouldAddBottomLoader = true
                case (false, false):
                    attribute.separatorLineStyle = .indent
                }
            }   // end for

            var newSnapshot = NSDiffableDataSourceSnapshot<TimelineSection, TimelineItem>()
            newSnapshot.appendSections([.main])
            newSnapshot.appendItems(newTimelineItems, toSection: .main)
            
            let endSnapshot = CACurrentMediaTime()
            let count = max(1, newSnapshot.itemIdentifiers.count)
            os_log("%{public}s[%{public}ld], %{public}s: calculate home timeline snapshot with %ld items cost %.2fs. avg %.5fs per item", ((#file as NSString).lastPathComponent), #line, #function, newSnapshot.itemIdentifiers.count, endSnapshot - endPrepareCache, (endSnapshot - endPrepareCache) / Double(count))
            
            DispatchQueue.main.async {
                if shouldAddBottomLoader, !(self.loadoldestStateMachine.currentState is LoadOldestState.NoMore) {
                    newSnapshot.appendItems([.bottomLoader], toSection: .main)
                }
                
                guard let difference = self.calculateReloadSnapshotDifference(navigationBar: navigationBar, tableView: tableView, oldSnapshot: oldSnapshot, newSnapshot: newSnapshot) else {
                    diffableDataSource.apply(newSnapshot)
                    self.isFetchingLatestTimeline.value = false
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
        let sourceIndexPath = UIViewController.topVisibleTableViewCellIndexPath(in: tableView, navigationBar: navigationBar) ?? IndexPath(row: 0, section: 0)
        
        guard sourceIndexPath.row < oldSnapshot.itemIdentifiers(inSection: .main).count else { return nil }
        
        let timelineItem = oldSnapshot.itemIdentifiers(inSection: .main)[sourceIndexPath.row]
        guard let itemIndex = newSnapshot.itemIdentifiers(inSection: .main).firstIndex(of: timelineItem) else { return nil }
        let targetIndexPath = IndexPath(row: itemIndex, section: 0)
        
        let offset = UIViewController.tableViewCellOriginOffsetToWindowTop(in: tableView, at: sourceIndexPath, navigationBar: navigationBar)
        return Difference(
            item: timelineItem,
            sourceIndexPath: sourceIndexPath,
            targetIndexPath: targetIndexPath,
            offset: offset
        )
    }
    
}

extension HomeTimelineViewModel {
    private static let secondStepTimerTriggered = Notification.Name("com.twidere.twiderex.home-timeline.second-step-timer-triggered")
}
