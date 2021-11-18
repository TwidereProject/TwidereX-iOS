//
//  ComposeContentViewModel+Diffable.swift
//  AppShared
//
//  Created by MainasuK on 2021/11/17.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereCore

extension ComposeContentViewModel {
    public enum Section: Hashable {
        case main
    }
    
    public enum Item: Int, Hashable, CaseIterable, Comparable {
        case replyTo
        case input
        case quote
        case attachment
        case poll
        
        public static func < (lhs: ComposeContentViewModel.Item, rhs: ComposeContentViewModel.Item) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
}

extension ComposeContentViewModel {
    public func setupDiffableDataSource(
        tableView: UITableView
    ) {
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            return self.cell(for: item, at: indexPath)
        }
                
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items.sorted(), toSection: .main)
        
        diffableDataSource?.applySnapshotUsingReloadData(snapshot, completion: nil)
        
        $items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
                snapshot.appendSections([.main])
                let sortedItems = items.sorted()
                snapshot.appendItems(sortedItems, toSection: .main)
                diffableDataSource.apply(snapshot)
            }
            .store(in: &disposeBag)
        
        composeInputTableViewCell.composeText
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let _ = self else { return }
                UIView.setAnimationsEnabled(false)
                tableView.beginUpdates()
                tableView.endUpdates()
                UIView.setAnimationsEnabled(true)
            }
            .store(in: &disposeBag)
        
    }
    
    private func cell(for item: Item, at indexPath: IndexPath) -> UITableViewCell {
        switch item {
        case .replyTo:
            let cell = UITableViewCell()
            cell.backgroundColor = .red
            return cell
        case .input:
            return composeInputTableViewCell
        case .quote:
            let cell = UITableViewCell()
            cell.backgroundColor = .yellow
            return cell
        case .attachment:
            let cell = UITableViewCell()
            cell.backgroundColor = .green
            return cell
        case .poll:
            let cell = UITableViewCell()
            cell.backgroundColor = .cyan
            return cell
        }
    }
}
