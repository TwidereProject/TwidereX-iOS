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
    case homeTimelineFeed(record: ManagedObjectRecord<Feed>)
    case twitterStatus(record: ManagedObjectRecord<TwitterStatus>)
}
