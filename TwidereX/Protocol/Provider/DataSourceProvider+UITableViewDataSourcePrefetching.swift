//
//  DataSourceProvider+UITableViewDataSourcePrefetching.swift
//  TwidereX
//
//  Created by MainasuK on 2023/4/7.
//  Copyright © 2023 Twidere. All rights reserved.
//

import UIKit
import CollectionConcurrencyKit

extension UITableViewDelegate where Self: DataSourceProvider {
    func aspectTableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        Task {
//            let itmes: [DataSourceItem] = await indexPaths
//                .concurrentCompactMap { [weak self] indexPath -> DataSourceItem? in
//                    guard let self = self else { return nil }
//                    return await self.item(from: .init(indexPath: indexPath))
//                }
//
//            var statusRecords: [StatusRecord] = []
//            var userRecords: [UserRecord] = []
//            for item in itmes {
//                switch item {
//                case .status(let record):       statusRecords.append(record)
//                case .user(let record):         userRecords.append(record)
//                case .notification:
//                    continue
//                }
//            }
        }   // end Task
    }
}
