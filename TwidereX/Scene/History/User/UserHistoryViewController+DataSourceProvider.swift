//
//  UserHistoryViewController+DataSourceProvider.swift
//  TwidereX
//
//  Created by MainasuK on 2022-8-1.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit

extension UserHistoryViewController: DataSourceProvider {
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
        case .history(let record):
            let managedObjectContext = context.managedObjectContext
            let item: DataSourceItem? = await managedObjectContext.perform {
                guard let history = record.object(in: managedObjectContext) else { return nil }
                guard let user = history.userObject else { return nil }
                return .user(user.asRecord)
                        
            }
            return item
        }
    }
    
    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
}
