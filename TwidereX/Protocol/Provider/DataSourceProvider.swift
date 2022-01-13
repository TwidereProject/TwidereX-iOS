//
//  DataSourceProvider.swift
//  DataSourceProvider
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import CoreDataStack
import UIKit

enum DataSourceItem: Hashable {
    case status(StatusRecord)
    case user(UserRecord)
    case notification(NotificationRecord)
}

extension DataSourceItem {
    struct Source {
        let collectionViewCell: UICollectionViewCell?
        let tableViewCell: UITableViewCell?
        let indexPath: IndexPath?
        
        init(
            collectionViewCell: UICollectionViewCell? = nil,
            tableViewCell: UITableViewCell? = nil,
            indexPath: IndexPath? = nil
        ) {
            self.collectionViewCell = collectionViewCell
            self.tableViewCell = tableViewCell
            self.indexPath = indexPath
        }
    }
}

protocol DataSourceProvider: NeedsDependency & UIViewController {
    var logger: Logger { get } 
    func item(from source: DataSourceItem.Source) async -> DataSourceItem?
}
