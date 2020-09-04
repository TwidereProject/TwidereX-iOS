//
//  Tweet.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-4.
//

import Foundation
import CoreDataStack
import TwitterAPI

extension Tweet.Property {
    init(entity: Twitter.Entity.Tweet, networkDate: Date) {
        self.init(
            idStr: entity.idStr,
            createdAt: entity.createdAt,
            text: entity.text,
            networkData: networkDate
        )
    }
}
