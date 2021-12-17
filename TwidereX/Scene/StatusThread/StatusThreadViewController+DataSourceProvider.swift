//
//  StatusThreadViewController+DataSourceProvider.swift
//  StatusThreadViewController+DataSourceProvider
//
//  Created by Cirno MainasuK on 2021-9-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

extension StatusThreadViewController: DataSourceProvider {
    func item(from source: DataSourceItem.Source) async -> DataSourceItem? {
        var _indexPath = source.indexPath
        if _indexPath == nil, let cell = source.tableViewCell {
            _indexPath = await self.indexPath(for: cell)
        }
        guard let indexPath = _indexPath else { return nil }

        guard let item = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else {
            return nil
        }
        
        guard case let .thread(thread) = item else { return nil }
        switch thread {
        case .reply(let threadContext),
             .root(let threadContext),
             .leaf(let threadContext):
            return .status(threadContext.status)
        }
    }
    
    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
}

