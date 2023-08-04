//
//  StatusItem.swift
//  StatusItem
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import TwidereCore

enum StatusItem: Hashable, DifferenceItem {
    case feed(record: ManagedObjectRecord<Feed>)
    case feedLoader(record: ManagedObjectRecord<Feed>)
    case status(StatusRecord)
    case topLoader
    case bottomLoader
    
    var isTransient: Bool {
        switch self {
        case .topLoader, .bottomLoader:     return true
        default:                            return false
        }
    }
}
