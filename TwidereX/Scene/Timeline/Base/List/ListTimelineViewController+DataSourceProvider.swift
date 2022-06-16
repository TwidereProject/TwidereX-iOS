//
//  TimelineViewController+DataSourceProvider.swift
//
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

extension ListTimelineViewController: DataSourceProvider {
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
                switch feed.kind {
                case .home:
                    if let status = feed.twitterStatus {
                        return .status(.twitter(record: .init(objectID: status.objectID)))
                    } else if let status = feed.mastodonStatus {
                        return .status(.mastodon(record: .init(objectID: status.objectID)))
                    } else {
                        return nil
                    }
                default:
                    return nil
                }   // end switch
            }
            return item
        case .status(let record):
            return .status(record)
        default:
            return nil
        }
    }
    
    @MainActor
    private func indexPath(for cell: UITableViewCell) async -> IndexPath? {
        return tableView.indexPath(for: cell)
    }
}
