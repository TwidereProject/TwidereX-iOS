//
//  StatusThreadViewModel+Diffable.swift
//  StatusThreadViewModel+Diffable
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack

extension StatusThreadViewModel {
    
    @MainActor func setupDiffableDataSource(
        tableView: UITableView,
        statusViewTableViewCellDelegate: StatusViewTableViewCellDelegate
    ) {
        let configuration = StatusSection.Configuration(
            statusViewTableViewCellDelegate: statusViewTableViewCellDelegate,
            timelineMiddleLoaderTableViewCellDelegate: nil
        )
        diffableDataSource = StatusSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: configuration
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
        snapshot.appendSections([.main])
        if hasReplyTo {
            snapshot.appendItems([.topLoader], toSection: .main)
        }
        if let root = self.root.value, case let .root(threadContext) = root {
            switch threadContext.status {
            case .twitter(let record):
                if twitterStatusThreadReplyViewModel.root == nil {
                    twitterStatusThreadReplyViewModel.root = record
                }
            case .mastodon:
                break
            }
            
            let item = StatusItem.thread(root)
            snapshot.appendItems([item, .bottomLoader], toSection: .main)
        } else {
            root.eraseToAnyPublisher()
                .sink { [weak self] root in
                    guard let self = self else { return }
                    
                    guard case .root(let threadContext) = root else { return }
                    guard case let .twitter(record) = threadContext.status else { return }

                    guard self.twitterStatusThreadReplyViewModel.root == nil else { return }
                    self.twitterStatusThreadReplyViewModel.root = record
                }
                .store(in: &disposeBag)
        }
        diffableDataSource?.apply(snapshot)
        
        // trigger thread loading
        loadThreadStateMachine.enter(LoadThreadState.Prepare.self)
        
        Publishers.CombineLatest3(
            root,
            $replies.removeDuplicates(),
            $leafs.removeDuplicates()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] root, replies, leafs in
            guard let self = self else { return }
            guard let diffableDataSource = self.diffableDataSource else { return }

            Task { @MainActor in
                let oldSnapshot = diffableDataSource.snapshot()

                var newSnapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
                newSnapshot.appendSections([.main])

                // top loader
                if self.hasReplyTo, case let .root(threadContext) = root {
                    switch threadContext.status {
                    case .twitter:
                        let state = self.twitterStatusThreadReplyViewModel.stateMachine.currentState
                        if state is TwitterStatusThreadReplyViewModel.State.NoMore {
                            // do nothing
                        } else {
                            newSnapshot.appendItems([.topLoader], toSection: .main)
                        }
                    case .mastodon:
                        let state = self.loadThreadStateMachine.currentState
                        if state is LoadThreadState.NoMore {
                            // do nothing
                        } else {
                            newSnapshot.appendItems([.topLoader], toSection: .main)
                        }
                    }
                }
                // replies
                newSnapshot.appendItems(replies.reversed(), toSection: .main)
                // root
                if let root = root {
                    let item = StatusItem.thread(root)
                    newSnapshot.appendItems([item], toSection: .main)
                }
                // leafs
                newSnapshot.appendItems(leafs, toSection: .main)
                // bottom loader
                if let currentState = self.loadThreadStateMachine.currentState {
                    switch currentState {
                    case is LoadThreadState.Prepare,
                         is LoadThreadState.Idle,
                         is LoadThreadState.Loading:
                        newSnapshot.appendItems([.bottomLoader], toSection: .main)
                    default:
                        break
                    }
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
                    await self.updateDataSource(snapshot: newSnapshot, animatingDifferences: false)
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot without tweak")
                    return
                }
                
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Snapshot] oldSnapshot: \(oldSnapshot.itemIdentifiers.debugDescription)")
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Snapshot] newSnapshot: \(newSnapshot.itemIdentifiers.debugDescription)")
                await self.updateSnapshotUsingReloadData(
                    tableView: tableView,
                    oldSnapshot: oldSnapshot,
                    newSnapshot: newSnapshot,
                    difference: difference
                )
            }
        }
        .store(in: &disposeBag)
    }
    
    @MainActor private func updateDataSource(
        snapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>,
        animatingDifferences: Bool
    ) async {
        await self.diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    // Some UI tweaks to present replies and conversation smoothly
    @MainActor private func updateSnapshotUsingReloadData(
        tableView: UITableView,
        oldSnapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>,
        newSnapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>,
        difference: StatusThreadViewModel.Difference // <StatusItem>
    ) async {
        let replies: [StatusItem] = {
            newSnapshot.itemIdentifiers.filter { item in
                guard case let .thread(thread) = item else { return false }
                guard case .reply = thread else { return false }
                return true
            }
        }()
        // additional margin for .topLoader
        let oldTopMargin: CGFloat = {
            let marginHeight = TimelineTopLoaderTableViewCell.cellHeight
            if oldSnapshot.itemIdentifiers.contains(.topLoader) || !replies.isEmpty {
                return marginHeight
            }
            return .zero
        }()
        
        await self.diffableDataSource?.applySnapshotUsingReloadData(newSnapshot)

        // note:
        // tweak the content offset and bottom inset
        // make the table view stable when data reload
        // the keypoint is set the bottom inset to make the root padding with "TopLoaderHeight" to top edge
        // and restore the "TopLoaderHeight" when bottom inset adjusted
        
        // set bottom inset. Make root item pin to top.
        if let item = root.value.flatMap({ StatusItem.thread($0) }),
           let index = newSnapshot.indexOfItem(item),
           let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
        {
            // always set bottom inset due to lazy reply loading
            // otherwise tableView will jump when insert replies
            let bottomSpacing = tableView.safeAreaLayoutGuide.layoutFrame.height - cell.frame.height - oldTopMargin
            let additionalInset = round(tableView.contentSize.height - cell.frame.maxY)
            
            tableView.contentInset.bottom = max(0, bottomSpacing - additionalInset)
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): content inset bottom: \(tableView.contentInset.bottom)")
        }

        // set scroll position
        tableView.scrollToRow(at: difference.targetIndexPath, at: .top, animated: false)
        tableView.contentOffset.y = {
            var offset: CGFloat = tableView.contentOffset.y - difference.sourceDistanceToTableViewTopEdge
            if tableView.contentInset.bottom != 0.0 {
                // needs restore top margin if bottom inset adjusted
                offset += oldTopMargin
            }
            return offset
        }()
        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot")
    }
}

extension StatusThreadViewModel {
    struct Difference {
        let item: StatusItem
        let sourceIndexPath: IndexPath
        let sourceDistanceToTableViewTopEdge: CGFloat
        let targetIndexPath: IndexPath
    }

    @MainActor private func calculateReloadSnapshotDifference(
        tableView: UITableView,
        oldSnapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>,
        newSnapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>
    ) -> Difference? {
        guard oldSnapshot.numberOfItems != 0 else { return nil }
        guard let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows?.sorted() else { return nil }

        // find index of the first visible item in both old and new snapshot
        var _index: Int?
        let items = oldSnapshot.itemIdentifiers(inSection: .main)
        for (i, item) in items.enumerated() {
            guard let indexPath = indexPathsForVisibleRows.first(where: { $0.row == i }) else { continue }
            guard newSnapshot.indexOfItem(item) != nil else { continue }
            let rectForCell = tableView.rectForRow(at: indexPath)
            let distanceToTableViewTopEdge = tableView.convert(rectForCell, to: nil).origin.y - tableView.safeAreaInsets.top
            guard distanceToTableViewTopEdge >= 0 else { continue }
            _index = i
            break
        }

        guard let index = _index else { return nil }
        let sourceIndexPath = IndexPath(row: index, section: 0)

        let rectForSourceItemCell = tableView.rectForRow(at: sourceIndexPath)
        let sourceDistanceToTableViewTopEdge = tableView.convert(rectForSourceItemCell, to: nil).origin.y - tableView.safeAreaInsets.top

        guard sourceIndexPath.section < oldSnapshot.numberOfSections,
              sourceIndexPath.row < oldSnapshot.numberOfItems(inSection: oldSnapshot.sectionIdentifiers[sourceIndexPath.section])
        else { return nil }

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
