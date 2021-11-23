//
//  ComposeContentViewModel+Diffable.swift
//  AppShared
//
//  Created by MainasuK on 2021/11/17.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import TwidereCore

extension ComposeContentViewModel {
    public enum Section: Hashable {
        case main
    }
    
    public enum Item: Int, Comparable, Hashable, CaseIterable {
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
            return self.cell(for: item, tableView: tableView, at: indexPath)
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
    }
    
    private func cell(for item: Item, tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        switch item {
        case .replyTo:
            guard let status = self.replyTo else {
                assertionFailure()
                return UITableViewCell()
            }
            composeReplyTableViewCell.prepareForReuse()
            composeReplyTableViewCell.configure(
                tableView: tableView,
                viewModel: ComposeReplyTableViewCell.ViewModel(
                    status: status,
                    statusViewConfigureContext: StatusView.ConfigurationContext(
                        dateTimeProvider: contentContext.dateTimeProvider,
                        twitterTextProvider: contentContext.twitterTextProvider,
                        activeAuthenticationContext: Just(nil).eraseToAnyPublisher()
                    )
                )
            )
            return composeReplyTableViewCell
        case .input:
            return composeInputTableViewCell
        case .quote:
            let cell = UITableViewCell()
            cell.backgroundColor = .yellow
            return cell
        case .attachment:
            return composeAttachmentTableViewCell
        case .poll:
            let cell = UITableViewCell()
            cell.backgroundColor = .cyan
            return cell
        }
    }
}
