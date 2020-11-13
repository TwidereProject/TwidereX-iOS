//
//  MentionTimelineViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-3.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import CoreData
import CoreDataStack
import GameplayKit

extension MentionTimelineViewModel {
    
    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource<TimelineSection, Item>(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .mentionTimelineIndex(let objectID, let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePostTableViewCell.self), for: indexPath) as! TimelinePostTableViewCell
                
                // configure cell
                let managedObjectContext = self.fetchedResultsController.managedObjectContext
                managedObjectContext.performAndWait {
                    let mentionTimelineIndex = managedObjectContext.object(with: objectID) as! MentionTimelineIndex
                    MentionTimelineViewModel.configure(cell: cell, readableLayoutFrame: tableView.readableContentGuide.layoutFrame, mentionTimelineIndex: mentionTimelineIndex, attribute: attribute)
                }
                cell.delegate = self.timelinePostTableViewCellDelegate
                return cell
            case .middleLoader(let upperTimelineIndexObjectID):
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
    
    static func configure(cell: TimelinePostTableViewCell, readableLayoutFrame: CGRect? = nil, mentionTimelineIndex: MentionTimelineIndex, attribute: Item.Attribute) {
        if let tweet = mentionTimelineIndex.tweet {
            HomeTimelineViewModel.configure(cell: cell, readableLayoutFrame: readableLayoutFrame, tweet: tweet, requestUserID: mentionTimelineIndex.userID)
            internalConfigure(cell: cell, tweet: tweet, attribute: attribute)
        }
    }
 
    private static func internalConfigure(cell: TimelinePostTableViewCell, tweet: Tweet, attribute: Item.Attribute) {
        // tweet date updater
        let createdAt = (tweet.retweet ?? tweet).createdAt
        NotificationCenter.default.publisher(for: MentionTimelineViewModel.secondStepTimerTriggered, object: nil)
            .sink { _ in
                cell.timelinePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            }
            .store(in: &cell.disposeBag)
        
        // quote date updater
        let quote = tweet.retweet?.quote ?? tweet.quote
        if let quote = quote {
            let createdAt = quote.createdAt
            cell.timelinePostView.quotePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            NotificationCenter.default.publisher(for: MentionTimelineViewModel.secondStepTimerTriggered, object: nil)
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
    
}


// MARK: - NSFetchedResultsControllerDelegate
extension MentionTimelineViewModel: NSFetchedResultsControllerDelegate {
    
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
            
            let mentionTimelineIndexes: [MentionTimelineIndex] = {
                let request = MentionTimelineIndex.sortedFetchRequest
                request.returnsObjectsAsFaults = false
                do {
                    return try managedObjectContext.fetch(request)
                } catch {
                    assertionFailure(error.localizedDescription)
                    return []
                }
            }()
            
            let endFetch = CACurrentMediaTime()
            os_log("%{public}s[%{public}ld], %{public}s: fetch mentionTimelineIndexes cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, endFetch - start)
            
            var oldSnapshotAttributeDict: [NSManagedObjectID : Item.Attribute] = [:]
            for item in oldSnapshot.itemIdentifiers {
                guard case let .mentionTimelineIndex(objectID, attribute) = item else { continue }
                oldSnapshotAttributeDict[objectID] = attribute
            }
            let endPrepareCache = CACurrentMediaTime()
            
            var newTimelineItems: [Item] = []
            
            os_log("%{public}s[%{public}ld], %{public}s: prepare timelineIndex cache cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, endPrepareCache - endFetch)
            for (i, mentionTimelineIndex) in mentionTimelineIndexes.enumerated() {
                let attribute = oldSnapshotAttributeDict[mentionTimelineIndex.objectID] ?? Item.Attribute()
                
                // append new item into snapshot
                newTimelineItems.append(.mentionTimelineIndex(objectID: mentionTimelineIndex.objectID, attribute: attribute))
                
                let isLast = i == mentionTimelineIndexes.count - 1
                switch (isLast, mentionTimelineIndex.hasMore) {
                case (true, false):
                    attribute.separatorLineStyle = .normal
                case (false, true):
                    attribute.separatorLineStyle = .expand
                    newTimelineItems.append(.middleLoader(upperTimelineIndexAnchorObjectID: mentionTimelineIndex.objectID))
                case (true, true):
                    attribute.separatorLineStyle = .normal
                    shouldAddBottomLoader = true
                case (false, false):
                    attribute.separatorLineStyle = .indent
                }
            }   // end for
            
            var newSnapshot = NSDiffableDataSourceSnapshot<TimelineSection, Item>()
            newSnapshot.appendSections([.main])
            newSnapshot.appendItems(newTimelineItems, toSection: .main)
            
            let endSnapshot = CACurrentMediaTime()
            let count = max(1, newSnapshot.itemIdentifiers.count)
            os_log("%{public}s[%{public}ld], %{public}s: calculate mention timeline snapshot with %ld items cost %.2fs. avg %.5fs per item", ((#file as NSString).lastPathComponent), #line, #function, newSnapshot.itemIdentifiers.count, endSnapshot - endPrepareCache, (endSnapshot - endPrepareCache) / Double(count))
            
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
