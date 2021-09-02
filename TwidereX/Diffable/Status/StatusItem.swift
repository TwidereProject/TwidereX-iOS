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
    case status(Status)
    case thread(Thread)
    case topLoader
    case bottomLoader
}

extension StatusItem {
    enum Status: Hashable {
        case twitter(record: ManagedObjectRecord<TwitterStatus>)
        case mastodon(record: ManagedObjectRecord<MastodonStatus>)
    }
}
 
extension StatusItem {
    enum Thread: Hashable {
        case root(status: Status)
        case reply(status: Status)
        case leaf(status: Status)
    }
}
