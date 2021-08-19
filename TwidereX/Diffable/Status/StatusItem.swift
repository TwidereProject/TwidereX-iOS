//
//  StatusItem.swift
//  StatusItem
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData

enum StatusItem: Hashable {
    case homeTimelineFeed(objectID: NSManagedObjectID)      // Feed
    case twitterStatus(objectID: NSManagedObjectID)         // TwitterStatus
}
