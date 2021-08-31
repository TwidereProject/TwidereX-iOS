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

enum DataSourceItem {
    case status(Status)
}

extension DataSourceItem {
    typealias Status = StatusItem.Status
    
    struct Source {
        let tableViewCell: UITableViewCell?
        let indexPath: IndexPath?
    }
}

protocol DataSourceProvider: NeedsDependency & UIViewController {
    var logger: Logger { get }
    func item(from source: DataSourceItem.Source) async -> DataSourceItem?
}
