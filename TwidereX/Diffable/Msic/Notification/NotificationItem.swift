//
//  NotificationItem.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack

enum NotificationItem: Hashable {
    case feed(record: ManagedObjectRecord<Feed>)
    case feedLoader(record: ManagedObjectRecord<Feed>)
    case bottomLoader
}
