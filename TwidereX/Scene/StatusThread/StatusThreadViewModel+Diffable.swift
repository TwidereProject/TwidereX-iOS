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
    func setupDiffableDataSource(
        tableView: UITableView,
        statusTableViewCellDelegate: StatusTableViewCellDelegate,
        statusThreadRootTableViewCellDelegate: StatusThreadRootTableViewCellDelegate
    ) {
        let configuration = StatusSection.Configuration(
            statusTableViewCellDelegate: statusTableViewCellDelegate,
            statusThreadRootTableViewCellDelegate: statusThreadRootTableViewCellDelegate,
            timelineMiddleLoaderTableViewCellDelegate: nil
        )
        diffableDataSource = StatusSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: configuration
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
        snapshot.appendSections([.main])
        if let root = self.root.value {
            let item = StatusItem.thread(root)
            snapshot.appendItems([item], toSection: .main)
        }
        diffableDataSource?.apply(snapshot)
        
        // trigger thread loading
        loadThreadStateMachine.enter(LoadThreadState.Prepare.self)
        
        let replies = mastodonStatusThreadViewModel.ancestors.eraseToAnyPublisher()
        let leafs = Publishers.CombineLatest(
            twitterStatusThreadLeafViewModel.items,
            mastodonStatusThreadViewModel.descendants
        )
        .map { $0 + $1 }
        
        Publishers.CombineLatest3(
            root,
            replies,
            leafs
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] root, replies, leafs in
            guard let self = self else { return }
            guard let diffableDataSource = self.diffableDataSource else { return }

            Task {
                let oldSnapshot = diffableDataSource.snapshot()

                var newSnapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
                // root
                newSnapshot.appendSections([.main])
                if let root = self.root.value {
                    let item = StatusItem.thread(root)
                    newSnapshot.appendItems([item], toSection: .main)
                }
                // leafs
                newSnapshot.appendItems(leafs, toSection: .main)
                
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
                
                guard let difference = await self.calculateReloadSnapshotDifference(
                    tableView: tableView,
                    oldSnapshot: oldSnapshot,
                    newSnapshot: newSnapshot
                ) else {
                    await self.updateDataSource(snapshot: newSnapshot, animatingDifferences: false)
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot")
                    return
                }
                
                await self.updateSnapshotUsingReloadData(snapshot: newSnapshot)
                await tableView.scrollToRow(at: difference.targetIndexPath, at: .top, animated: false)
                var contentOffset = await tableView.contentOffset
                contentOffset.y = await tableView.contentOffset.y - difference.sourceDistanceToTableViewTopEdge
                await tableView.setContentOffset(contentOffset, animated: false)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot")
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
    
    @MainActor private func updateSnapshotUsingReloadData(
        snapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>
    ) async {
        await self.diffableDataSource?.applySnapshotUsingReloadData(snapshot)
    }
}

extension StatusThreadViewModel {
    struct Difference<T> {
        let item: T
        let sourceIndexPath: IndexPath
        let sourceDistanceToTableViewTopEdge: CGFloat
        let targetIndexPath: IndexPath
    }
    
    @MainActor private func calculateReloadSnapshotDifference<S: Hashable, T: Hashable>(
        tableView: UITableView,
        oldSnapshot: NSDiffableDataSourceSnapshot<S, T>,
        newSnapshot: NSDiffableDataSourceSnapshot<S, T>
    ) -> Difference<T>? {
        guard let sourceIndexPath = (tableView.indexPathsForVisibleRows ?? []).sorted().first else { return nil }
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
