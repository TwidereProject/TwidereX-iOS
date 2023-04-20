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
        
        switch item {
        case .root:
            guard let status = viewModel.statusViewModel?.status?.asRecord else  { return nil }
            return .status(status)
        case .status(let status):
            return .status(status)
        case .topLoader, .bottomLoader:
            return nil
        }
    }
    
    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
}

