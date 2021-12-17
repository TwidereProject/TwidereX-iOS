//
//  AccountListViewController+DataSourceProvider.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-16.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

extension AccountListViewController: DataSourceProvider {
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
        case .authenticationIndex(let record):
            let managedObjectContext = context.managedObjectContext
            let item: DataSourceItem? = await managedObjectContext.perform {
                guard let authenticationIndex = record.object(in: managedObjectContext) else { return nil }
                guard let record = authenticationIndex.user?.asRecord else { return nil }
                return .user(record)
            }
            return item
        default:
            return nil
        }
    }
    
    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
}
