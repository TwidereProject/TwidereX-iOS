//
//  FollowerListViewController+DataSourceProvider.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-3.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

// MARK: - DataSourceProvider
extension FollowerListViewController: DataSourceProvider {
    
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
        case .user(let record, _):
            return .user(record)
        default:
            return nil
        }
    }
    
    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
    
}
