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
            entities: entity.entities,
            extendedEntities: entity.extendedEntities,
            source: entity.source,
            coordinates: entity.coordinates,
            place: entity.place,
            retweetCount: entity.retweetCount,
            retweeted: entity.retweeted ?? false,
            favoriteCount: entity.favoriteCount,
            favorited: entity.favorited ?? false,
            quotedStatusIDStr: entity.quotedStatusIDStr,
            conversationID: nil,        // v2
            networkData: networkDate
        )
    }
}
