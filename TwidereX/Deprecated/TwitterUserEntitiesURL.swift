//
//  TwitterUserEntitiesURL.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-26.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import TwitterSDK

extension TwitterUserEntitiesURL.Property {
    static func properties(from entities: Twitter.Entity.User.Entities, networkDate: Date) -> [TwitterUserEntitiesURL.Property] {
        var properties: [TwitterUserEntitiesURL.Property] = []
        if let urlEntities = entities.url?.urls {
            let newProperties = urlEntities.compactMap { urlEntity -> TwitterUserEntitiesURL.Property? in
                guard let indices = urlEntity.indices, indices.count == 2 else { return nil }
                return TwitterUserEntitiesURL.Property(start: indices[0], end: indices[1], url: urlEntity.url, expandedURL: urlEntity.expandedURL, displayURL: urlEntity.displayURL, networkDate: networkDate)
            }
            properties.append(contentsOf: newProperties)
        }
        if let urlEntities = entities.description?.urls {
            let newProperties = urlEntities.compactMap { urlEntity -> TwitterUserEntitiesURL.Property? in
                guard let indices = urlEntity.indices, indices.count == 2 else { return nil }
                return TwitterUserEntitiesURL.Property(start: indices[0], end: indices[1], url: urlEntity.url, expandedURL: urlEntity.expandedURL, displayURL: urlEntity.displayURL, networkDate: networkDate)
            }
            properties.append(contentsOf: newProperties)
        }
        return properties
    }
}
