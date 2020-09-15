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

final class HomeTimelineViewModel: NSObject {
    
    // input
    let context: AppContext
    let fetchedResultsController: NSFetchedResultsController<TimelineIndex>
    let isFetchingLatestTimeline = CurrentValueSubject<Bool, Never>(false)
    weak var contentOffsetAdjustableTimelineViewControllerDelegate: ContentOffsetAdjustableTimelineViewControllerDelegate?
    weak var tableView: UITableView?
    
    // output
    var currentTwitterAuthentication = CurrentValueSubject<TwitterAuthentication?, Never>(nil)
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
    }
    
}

extension HomeTimelineViewModel {

    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .homeTimelineIndex(let objectID, let expandStatus):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: HomeTimelineTableViewCell.self), for: indexPath) as! HomeTimelineTableViewCell
                
                // configure cell
                let managedObjectContext = self.fetchedResultsController.managedObjectContext
                managedObjectContext.performAndWait {
                    let timelineIndex = managedObjectContext.object(with: objectID) as! TimelineIndex
                    HomeTimelineViewModel.configure(cell: cell, timelineIndex: timelineIndex, expandStatus: expandStatus)
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
    
    static func configure(cell: HomeTimelineTableViewCell, timelineIndex: TimelineIndex, expandStatus: TimelineItem.ExpandStatus) {
        if let tweet = timelineIndex.tweet {
            configure(cell: cell, tweet: tweet, expandStatus: expandStatus)
        }
    }

    private static func configure(cell: HomeTimelineTableViewCell, tweet: Tweet, expandStatus: TimelineItem.ExpandStatus) {
        // set retweet display
        cell.retweetContainerStackView.isHidden = tweet.retweet == nil ? true : false
        cell.retweetInfoLabel.text = tweet.user.name.flatMap { $0 + " Retweeted" } ?? " "
        
        // set avatar
        if let avatarImageURL = (tweet.retweet?.user ?? tweet.user).avatarImageURL() {
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
        cell.nameLabel.text = (tweet.retweet?.user ?? tweet.user).name
        cell.usernameLabel.text = (tweet.retweet?.user ?? tweet.user).screenName.flatMap { "@" + $0 }

        // set date
        let createdAt = (tweet.retweet ?? tweet).createdAt
        cell.dateLabel.text = createdAt.shortTimeAgoSinceNow
        cell.dateLabelUpdateSubscription = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .sink { _ in
                // do not use core date entity in this run loop
                cell.dateLabel.text = createdAt.shortTimeAgoSinceNow
            }
        
        // set text
        cell.activeTextLabel.text = (tweet.retweet ?? tweet).text
        
        // set panel
        let retweetCountTitle: String = {
            let count = (tweet.retweet ?? tweet).retweetCount.flatMap { Int(truncating: $0) }
            return HomeTimelineTableViewCell.formattedNumberTitleForButton(count)
        }()
        cell.retweetButton.setTitle(retweetCountTitle, for: .normal)
        
        let favoriteCountTitle: String = {
            let count = (tweet.retweet ?? tweet).favoriteCount.flatMap { Int(truncating: $0) }
            return HomeTimelineTableViewCell.formattedNumberTitleForButton(count)
        }()
        cell.favoriteButton.setTitle(favoriteCountTitle, for: .normal)
        
        
        // set image display
        let media = tweet.extendedEntities?.media ?? []
        for subview in cell.tweetImageContainerStackView.arrangedSubviews {
            cell.tweetImageContainerStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        var mosaicMetas: [MosaicMeta] = []
        for element in media {
            guard let (url, size) = element.photoURL(sizeKind: .small) else { continue }
            let meta = MosaicMeta(url: url, size: size)
            mosaicMetas.append(meta)
        }
        cell.tweetImageContainerStackView.isHidden = mosaicMetas.isEmpty
        if mosaicMetas.count == 1 {
            let maxHeight = HomeTimelineTableViewCell.tweetImageContainerStackViewMaxHeight
            let meta = mosaicMetas[0]
            let rect = AVMakeRect(aspectRatio: meta.size, insideRect: CGRect(origin: .zero, size: CGSize(width: cell.tweetImageContainerStackView.frame.width, height: maxHeight)))
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.af.setImage(
                withURL: meta.url,
                placeholderImage: UIImage.placeholder(color: .systemFill),
                imageTransition: .crossDissolve(0.2)
            )
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            cell.tweetImageContainerStackView.addArrangedSubview(container)
            
            imageView.layer.masksToBounds = true
            imageView.layer.cornerRadius = 8
            imageView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: container.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                imageView.widthAnchor.constraint(equalToConstant: rect.width),
            ])

            cell.tweetImageContainerStackViewHeightLayoutConstraint.constant = rect.height
            // os_log("%{public}s[%{public}ld], %{public}s: preview image %s", ((#file as NSString).lastPathComponent), #line, #function, meta.url.debugDescription)
        } else {
            let imageViews: [UIImageView] = mosaicMetas.map { meta in
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.af.setImage(
                    withURL: meta.url,
                    placeholderImage: UIImage.placeholder(color: .systemFill),
                    imageTransition: .crossDissolve(0.2)
                )
                return imageView
            }
            
            let leftVerticalStackView: UIStackView = {
                let stackView = UIStackView()
                stackView.axis = .vertical
                stackView.distribution = .fillEqually
                return stackView
            }()
            let rightVerticalStackView: UIStackView = {
                let stackView = UIStackView()
                stackView.axis = .vertical
                stackView.distribution = .fillEqually
                return stackView
            }()
            cell.tweetImageContainerStackView.addArrangedSubview(leftVerticalStackView)
            cell.tweetImageContainerStackView.addArrangedSubview(rightVerticalStackView)
            imageViews.forEach {
                $0.layer.masksToBounds = true
            }
            
            if mosaicMetas.count == 2 {
                leftVerticalStackView.addArrangedSubview(imageViews[0])
                rightVerticalStackView.addArrangedSubview(imageViews[1])
            } else if mosaicMetas.count == 3 {
                leftVerticalStackView.addArrangedSubview(imageViews[0])
                rightVerticalStackView.addArrangedSubview(imageViews[1])
                rightVerticalStackView.addArrangedSubview(imageViews[2])
            } else if mosaicMetas.count == 4 {
                leftVerticalStackView.addArrangedSubview(imageViews[0])
                rightVerticalStackView.addArrangedSubview(imageViews[1])
                leftVerticalStackView.addArrangedSubview(imageViews[2])
                rightVerticalStackView.addArrangedSubview(imageViews[3])
            }
            
            cell.tweetImageContainerStackViewHeightLayoutConstraint.constant = HomeTimelineTableViewCell.tweetImageContainerStackViewDefaultHeight
        }
        
        // set quote display
        let quote = tweet.retweet?.quote ?? tweet.quote
        if let quote = quote {
            // set avatar
            if let avatarImageURL = quote.user.avatarImageURL() {
                let placeholderImage = UIImage
                    .placeholder(size: HomeTimelineTableViewCell.avatarImageViewSize, color: .systemFill)
                    .af.imageRoundedIntoCircle()
                let filter = ScaledToSizeCircleFilter(size: HomeTimelineTableViewCell.avatarImageViewSize)
                cell.quoteView.avatarImageView.af.setImage(
                    withURL: avatarImageURL,
                    placeholderImage: placeholderImage,
                    filter: filter,
                    imageTransition: .crossDissolve(0.2)
                )
            } else {
                assertionFailure()
            }
            
            // set name and username
            cell.quoteView.nameLabel.text = quote.user.name
            cell.quoteView.usernameLabel.text = quote.user.screenName.flatMap { "@" + $0 }
            
            // set date
            let createdAt = quote.createdAt
            cell.quoteView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            cell.quoteDateLabelUpdateSubscription = Timer.publish(every: 1, on: .main, in: .default)
                .autoconnect()
                .sink { _ in
                    // do not use core date entity in this run loop
                    cell.quoteView.dateLabel.text = createdAt.shortTimeAgoSinceNow
                }
            
            // set text
            cell.quoteView.activeTextLabel.text = quote.text
        }
        
        cell.tweetQuoteContainerStackView.isHidden = quote == nil
        // set panel display
        cell.tweetPanelContainerStackView.alpha = !expandStatus.isExpand ? 0 : 1
        cell.tweetPanelContainerStackView.isHidden = !expandStatus.isExpand
    }
    
    struct MosaicMeta {
        let url: URL
        let size: CGSize
    }
    
}

extension HomeTimelineViewModel {
    func focus(cell: HomeTimelineTableViewCell, in tableView: UITableView, at indexPath: IndexPath)  {
        guard let diffableDataSource = self.diffableDataSource else {
            assertionFailure()
            return
        }
        
        guard let focusedTimelineItem = diffableDataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        var snapshot = diffableDataSource.snapshot()
        
        var reloadItems: Set<TimelineItem> = Set()
        for item in snapshot.itemIdentifiers where item != focusedTimelineItem {
            switch item {
            case .homeTimelineIndex(_, let expandStatus) where expandStatus.isExpand:
                expandStatus.isExpand = false
                reloadItems.insert(item)
            default:
                continue
            }
        }
        
        switch focusedTimelineItem {
        case .homeTimelineIndex(_, let expandStatus):
            expandStatus.isExpand.toggle()
            reloadItems.insert(focusedTimelineItem)
        default:
            break
        }
        
        snapshot.reloadItems(Array(reloadItems))
        diffableDataSource.defaultRowAnimation = .none
        diffableDataSource.apply(snapshot) // set animation in cell
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
                let expandStatus: TimelineItem.ExpandStatus = {
                    for item in oldSnapshot.itemIdentifiers {
                        guard case let .homeTimelineIndex(oldObjectID, expandStatus) = item else { continue }
                        guard objectID == oldObjectID else { continue }
                        return expandStatus
                    }
                    
                    return TimelineItem.ExpandStatus()
                }()
                
                // save into buffer
                newSnapshot.appendItems([.homeTimelineIndex(objectID: objectID, expandStatus: expandStatus)], toSection: .main)

                let timelineIndex = managedObjectContext.object(with: objectID) as! TimelineIndex
                if let tweet = timelineIndex.tweet {
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
