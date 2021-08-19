//
//  TwitterStatus.swift
//  TwitterStatus
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack
import TwitterSDK

extension TwitterStatus.Property {
    init(entity: Twitter.Entity.Tweet, networkDate: Date) {
        self.init(
            id: entity.id,
            createdAt: entity.createdAt,
            updatedAt: networkDate
        )
    }
}
