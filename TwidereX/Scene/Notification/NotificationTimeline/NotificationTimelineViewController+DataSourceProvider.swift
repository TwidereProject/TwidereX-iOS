//
//  NotificationTimelineViewController+DataSourceProvider.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereCore

extension NotificationTimelineViewController: DataSourceProvider {
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
        case .feed(let record):
            let managedObjectContext = context.managedObjectContext
            let item: DataSourceItem? = await managedObjectContext.perform {
                guard let feed = record.object(in: managedObjectContext) else { return nil }
                let content = feed.content
                switch content {
                case .status(let object):
                    return .status(object.asRecord)
                case .notification(let object):
                    return .notification(object.asRecord)
                case .none:
                    return nil
                }
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
