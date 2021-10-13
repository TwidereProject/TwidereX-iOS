//
//  StatusItem.swift
//  StatusItem
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack

enum StatusItem: Hashable {
    case feed(record: ManagedObjectRecord<Feed>)
    case feedLoader(record: ManagedObjectRecord<Feed>)
    case status(StatusRecord)
    case thread(Thread)
    case topLoader
    case bottomLoader
}
 
extension StatusItem {
    enum Thread: Hashable {
        case root(status: StatusRecord)
        case reply(status: StatusRecord)
        case leaf(status: StatusRecord)
    }
}
