//
//  StatusThreadViewModel+Diffable.swift
//  StatusThreadViewModel+Diffable
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import Combine
import CoreData
import CoreDataStack

extension StatusThreadViewModel {
    
    @MainActor func setupDiffableDataSource(
        tableView: UITableView,
        statusViewTableViewCellDelegate: StatusViewTableViewCellDelegate
    ) {
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))

        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
            guard let self = self else { return UITableViewCell() }
            
            switch item {
            case .status(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                cell.delegate = statusViewTableViewCellDelegate
                self.context.managedObjectContext.performAndWait {
                    guard let status = record.object(in: self.context.managedObjectContext) else { return }
                    let viewModel = StatusView.ViewModel(
                        status: status,
                        authContext: self.authContext,
                        delegate: cell,
                        viewLayoutFramePublisher: self.$viewLayoutFrame
                    )
                    cell.contentConfiguration = UIHostingConfiguration {
                        StatusView(viewModel: viewModel)
                    }
                    .margins(.vertical, 0)  // remove vertical margins
                }
                return cell
            case .root:
                let cell = self.conversationRootTableViewCell
                guard let statusViewModel = self.statusViewModel else {
                    return UITableViewCell()
                }
                cell.delegate = statusViewTableViewCellDelegate
                cell.contentConfiguration = UIHostingConfiguration {
                    StatusView(viewModel: statusViewModel)
                }
                .margins(.vertical, 0)  // remove vertical margins
                return cell
            case .topLoader, .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            }
        }   // end diffableDataSource = UITableViewDiffableDataSource
        
        // initial snapshot
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        switch kind {
        case .status(let status):
            // top loader
            let hasReplyTo: Bool = {
                guard let status = status.object(in: context.managedObjectContext) else { return false }
                switch status {
                case .twitter(let status):      return status.replyToStatusID != nil
                case .mastodon(let status):     return status.replyToStatusID != nil
                }
            }()
            if hasReplyTo {
                snapshot.appendItems([.topLoader], toSection: .main)
            }
            // root
            snapshot.appendItems([.root])
            // bottom loader
            snapshot.appendItems([.bottomLoader])
        case .twitter, .mastodon:
            break
        }
        diffableDataSource?.apply(snapshot, animatingDifferences: false, completion: nil)
        
//        let configuration = StatusSection.Configuration(
//            statusViewTableViewCellDelegate: statusViewTableViewCellDelegate,
//            timelineMiddleLoaderTableViewCellDelegate: nil,
//            viewLayoutFramePublisher: $viewLayoutFrame
//        )
//
//        diffableDataSource = StatusSection.diffableDataSource(
//            tableView: tableView,
//            context: context,
//            authContext: authContext,
//            configuration: configuration
//        )
//
//        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
//        snapshot.appendSections([.main])
//        if hasReplyTo {
//            snapshot.appendItems([.topLoader], toSection: .main)
//        }
//        if let root = self.root.value, case let .root(threadContext) = root {
//            switch threadContext.status {
//            case .twitter(let record):
//                if twitterStatusThreadReplyViewModel.root == nil {
//                    twitterStatusThreadReplyViewModel.root = record
//                }
//            case .mastodon:
//                break
//            }
//
//            let item = StatusItem.thread(root)
//            snapshot.appendItems([item, .bottomLoader], toSection: .main)
//        } else {
//            root.eraseToAnyPublisher()
//                .sink { [weak self] root in
//                    guard let self = self else { return }
//
//                    guard case .root(let threadContext) = root else { return }
//                    guard case let .twitter(record) = threadContext.status else { return }
//
//                    guard self.twitterStatusThreadReplyViewModel.root == nil else { return }
//                    self.twitterStatusThreadReplyViewModel.root = record
//                }
//                .store(in: &disposeBag)
//        }
//        diffableDataSource?.apply(snapshot)
//
//        // trigger thread loading
//        loadThreadStateMachine.enter(LoadThreadState.Prepare.self)
//
        Publishers.CombineLatest4(
            $status,
            $topThreads.removeDuplicates(),
            $bottomThreads.removeDuplicates(),
            $deleteStatusIDs.removeDuplicates()
        )
        .debounce(for: 0.3, scheduler: DispatchQueue.main)
        .dropFirst()
        .sink { [weak self] status, topThreads, bottomThreads, deleteStatusIDs in
            guard let self = self else { return }
            guard let diffableDataSource = self.diffableDataSource else { return }

            Task { @MainActor in
                let oldSnapshot = diffableDataSource.snapshot()

                var newSnapshot = NSDiffableDataSourceSnapshot<Section, Item>()
                newSnapshot.appendSections([.main])

                // top loader
                switch self.topCursor {
                case .noMore:
                    break
                default:
                    // top loader
                    let hasReplyTo: Bool = {
                        switch status {
                        case .twitter(let status):      return status.replyToStatusID != nil
                        case .mastodon(let status):     return status.replyToStatusID != nil
                        case nil:                       return false
                        }
                    }()
                    if hasReplyTo {
                        newSnapshot.appendItems([.topLoader], toSection: .main)
                    }
                }
                // self reply
                let topItems: [Item] = topThreads.compactMap { thread -> Item? in
                    switch thread {
                    case .selfThread(let status):       return .status(status: status)
                    default:                            return nil
                    }
                }.removingDuplicates()
                newSnapshot.appendItems(topItems, toSection: .main)
                // root
                newSnapshot.appendItems([.root], toSection: .main)
                if let status = status, deleteStatusIDs.contains(status.id) {
                    newSnapshot.deleteItems([.root])
                }
                // bottom reply
                let bottomItems: [Item] = bottomThreads.compactMap { thread -> [Item]? in
                    switch thread {
                    case .conversationThread(let components):
                        return components.compactMap { status -> Item? in
//                            guard !deleteStatusIDs.contains(status.id) else {
//                                return nil
//                            }
                            return Item.status(status: status)
                        }
                    default:
                        assertionFailure()
                        return nil
                    }
                }
                .flatMap { $0 }
                .removingDuplicates()
                newSnapshot.appendItems(bottomItems, toSection: .main)
                // bottom loader
                switch self.bottomCursor {
                case .noMore:
                    break
                default:
                    newSnapshot.appendItems([.bottomLoader], toSection: .main)
                }

                let hasChanges = newSnapshot.itemIdentifiers != oldSnapshot.itemIdentifiers
                if !hasChanges {
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): snapshot not changes")
                    return
                } else {
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): snapshot has changes")
                }
                
                guard let difference = self.calculateReloadSnapshotDifference(
                    tableView: tableView,
                    oldSnapshot: oldSnapshot,
                    newSnapshot: newSnapshot
                ) else {
                    self.updateDataSource(snapshot: newSnapshot, animatingDifferences: false)
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot without tweak")
                    return
                }

                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Snapshot] oldSnapshot: \(oldSnapshot.itemIdentifiers.debugDescription)")
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Snapshot] newSnapshot: \(newSnapshot.itemIdentifiers.debugDescription)")
                self.reloadSnapshotWithDifference(
                    tableView: tableView,
                    oldSnapshot: oldSnapshot,
                    newSnapshot: newSnapshot,
                    difference: difference
                )
                
            }   // end Task
        }
        .store(in: &disposeBag)
    }

}

extension StatusThreadViewModel {
    struct Difference<T>: CustomStringConvertible {
        let item: T
        let sourceIndexPath: IndexPath
        let sourceDistanceToTableViewTopEdge: CGFloat
        let targetIndexPath: IndexPath
        
        var description: String {
            """
            source: \(sourceIndexPath.debugDescription)
            target: \(targetIndexPath.debugDescription)
            offset: \(sourceDistanceToTableViewTopEdge)
            item: \(String(describing: item))
            """
        }
    }
    
    @MainActor func calculateReloadSnapshotDifference<S: Hashable, T: Hashable & DifferenceItem>(
        tableView: UITableView,
        oldSnapshot: NSDiffableDataSourceSnapshot<S, T>,
        newSnapshot: NSDiffableDataSourceSnapshot<S, T>
    ) -> Difference<T>? {
        guard oldSnapshot.numberOfItems != 0 else { return nil }
        guard let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows?.sorted() else { return nil }

        // find index of the first visible item in both old and new snapshot
        var _index: Int?
        let items = oldSnapshot.itemIdentifiers
        for (i, item) in items.enumerated() {
            guard let _ = indexPathsForVisibleRows.first(where: { $0.row == i }) else { continue }
            guard !item.isTransient else { continue }
            guard newSnapshot.indexOfItem(item) != nil else { continue }
            _index = i
            break
        }

        guard let index = _index else { return nil }
        let sourceIndexPath = IndexPath(row: index, section: 0)

        let rectForSourceItemCell = tableView.rectForRow(at: sourceIndexPath)
        let sourceDistanceToTableViewTopEdge: CGFloat = {
            if tableView.window != nil {
                return tableView.convert(rectForSourceItemCell, to: nil).origin.y - tableView.safeAreaInsets.top
            } else {
                return rectForSourceItemCell.origin.y - tableView.contentOffset.y - tableView.safeAreaInsets.top
            }
        }()
        
        let sectionIdentifier = oldSnapshot.sectionIdentifiers[sourceIndexPath.section]
        let item = oldSnapshot.itemIdentifiers(inSection: sectionIdentifier)[sourceIndexPath.row]
        
        guard let targetIndexPathRow = newSnapshot.indexOfItem(item),
              let newSectionIdentifier = newSnapshot.sectionIdentifier(containingItem: item),
              let targetIndexPathSection = newSnapshot.indexOfSection(newSectionIdentifier)
        else { return nil }
        
        let targetIndexPath = IndexPath(row: targetIndexPathRow, section: targetIndexPathSection)
        
        return Difference(
            item: item,
            sourceIndexPath: sourceIndexPath,
            sourceDistanceToTableViewTopEdge: sourceDistanceToTableViewTopEdge,
            targetIndexPath: targetIndexPath
        )
    }
}

extension StatusThreadViewModel {
    @MainActor func updateDataSource(
        snapshot: NSDiffableDataSourceSnapshot<Section, Item>,
        animatingDifferences: Bool
    ) {
        diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    @MainActor func updateSnapshotUsingReloadData(
        snapshot: NSDiffableDataSourceSnapshot<Section, Item>
    ) {
        diffableDataSource?.applySnapshotUsingReloadData(snapshot)
    }
    
    @MainActor func reloadSnapshotWithDifference(
        tableView: UITableView,
        oldSnapshot: NSDiffableDataSourceSnapshot<Section, Item>,
        newSnapshot: NSDiffableDataSourceSnapshot<Section, Item>,
        difference: Difference<Item>
    ) {
        tableView.isUserInteractionEnabled = false
        tableView.panGestureRecognizer.isEnabled = false
        defer {
            tableView.isUserInteractionEnabled = true
            tableView.panGestureRecognizer.isEnabled = true
        }
        diffableDataSource?.applySnapshotUsingReloadData(newSnapshot)

        // set bottom inset
        
        guard let index = newSnapshot.indexOfItem(.root),
              let lastItem = newSnapshot.itemIdentifiers.last,
              let lastIndex = newSnapshot.indexOfItem(lastItem)
        else {
            return
        }
        let rectForCell = tableView.rectForRow(at: IndexPath(row: index, section: 0))
        let rectForLastCell = tableView.rectForRow(at: IndexPath(row: lastIndex, section: 0))
        let rectForTargetCell = tableView.rectForRow(at: difference.targetIndexPath)
        
        // always set bottom inset due to lazy reply loading
        // otherwise tableView will jump when insert replies
        let bottomSpacing = tableView.safeAreaLayoutGuide.layoutFrame.height - rectForCell.height - TimelineLoaderTableViewCell.cellHeight
        let additionalInset = round(rectForLastCell.maxY - rectForCell.maxY)
        let inset = bottomSpacing - max(0, additionalInset)
        tableView.contentInset.bottom = max(0, inset)
        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): content inset bottom: \(tableView.contentInset.bottom)")
        
        tableView.contentOffset.y = {
            var offset: CGFloat = rectForTargetCell.minY
            offset -= tableView.safeAreaInsets.top
            offset -= difference.sourceDistanceToTableViewTopEdge
            return offset
        }()
    }
}
