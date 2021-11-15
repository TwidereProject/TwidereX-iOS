//
//  NotificationTimelineViewController+DebugAction.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/15.
//  Copyright © 2021 Twidere. All rights reserved.
//

#if DEBUG

import os.log
import UIKit
import CoreData
import CoreDataStack

extension NotificationTimelineViewController {
    
    var debugActionBarButtonItem: UIBarButtonItem {
        let barButtonItem = UIBarButtonItem(title: "More", image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: moreMenu)
        return barButtonItem
    }
    
    var moreMenu: UIMenu {
        return UIMenu(
            title: "Debug Tools",
            image: nil,
            identifier: nil,
            options: .displayInline,
            children: [
                dropMenu,
            ]
        )
    }
    
    var dropMenu: UIMenu {
        return UIMenu(
            title: "Drop…",
            image: UIImage(systemName: "minus.circle"),
            identifier: nil,
            options: [],
            children: [1, 2, 5, 10, 20, 50, 100, 150, 200, 250, 300].map { count in
                UIAction(title: "Drop Recent \(count)", image: nil, attributes: [], handler: { [weak self] action in
                    guard let self = self else { return }
                    self.dropRecentFeedAction(action, count: count)
                })
            }
        )
    }
    
}

extension NotificationTimelineViewController {
    
    @objc private func dropRecentFeedAction(_ sender: UIAction, count: Int) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let snapshot = diffableDataSource.snapshot()
        
        let droppingObjectIDs = snapshot.itemIdentifiers.prefix(count).compactMap { item -> NSManagedObjectID? in
            switch item {
            case .feed(let record):         return record.objectID
            default:                        return nil
            }
        }
        context.apiService.backgroundManagedObjectContext.performChanges { [weak self] in
            guard let self = self else { return }
            for objectID in droppingObjectIDs {
                let feed = self.context.apiService.backgroundManagedObjectContext.object(with: objectID) as! Feed
                self.context.apiService.backgroundManagedObjectContext.delete(feed)
            }
        }
        .sink { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                assertionFailure(error.localizedDescription)
            }
        }
        .store(in: &disposeBag)
    }
    
}

#endif
