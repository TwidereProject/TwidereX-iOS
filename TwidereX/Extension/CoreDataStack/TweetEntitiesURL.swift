//
//  TweetEntitiesURL.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-27.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import TwitterAPI

extension TweetEntitiesURL.Property {
    
    static func properties(from entities: Twitter.Entity.Tweet.Entities, networkDate: Date) -> [TweetEntitiesURL.Property] {
        var properties: [TweetEntitiesURL.Property] = []
        if let urlEntities = entities.urls {
            let newProperties = urlEntities.compactMap { urlEntity -> TweetEntitiesURL.Property? in
                guard let indices = urlEntity.indices, indices.count == 2 else { return nil }
                return TweetEntitiesURL.Property(start: indices[0], end: indices[1], url: urlEntity.url, expandedURL: urlEntity.expandedURL, displayURL: urlEntity.displayURL, networkDate: networkDate)
            }
            properties.append(contentsOf: newProperties)
        }
        return properties
    }
    
    static func properties(from entities: Twitter.Entity.ExtendedEntities, networkDate: Date) -> [TweetEntitiesURL.Property] {
        var properties: [TweetEntitiesURL.Property] = []
        if let mediaEntities = entities.media {
            let newProperties = mediaEntities.compactMap { urlEntity -> TweetEntitiesURL.Property? in
                guard let indices = urlEntity.indices, indices.count == 2 else { return nil }
                let property = TweetEntitiesURL.Property(start: indices[0], end: indices[1], url: urlEntity.url, expandedURL: urlEntity.expandedURL, displayURL: urlEntity.displayURL, unwoundURL: nil, networkDate: networkDate)
                return property
            }
            properties.append(contentsOf: newProperties)
        }
        return properties
    }
    
}

extension TweetEntitiesURL.Property {
    static func properties(from entities: Twitter.Entity.V2.Entities, networkDate: Date) -> [TweetEntitiesURL.Property] {
        var properties: [TweetEntitiesURL.Property] = []
        if let urlEntities = entities.urls {
            let newProperties = urlEntities.compactMap { urlEntity -> TweetEntitiesURL.Property? in
                let property = TweetEntitiesURL.Property(start: urlEntity.start, end: urlEntity.end, url: urlEntity.url, expandedURL: urlEntity.expandedURL, displayURL: urlEntity.displayURL, unwoundURL: urlEntity.unwoundURL, networkDate: networkDate)
                return property
            }
            properties.append(contentsOf: newProperties)
        }
        return properties
    }
}
