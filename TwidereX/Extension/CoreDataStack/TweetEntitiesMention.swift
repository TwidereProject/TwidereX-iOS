//
//  TweetEntitiesMention.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-27.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import TwitterAPI

extension TweetEntitiesMention.Property {
    static func properties(from entities: Twitter.Entity.Tweet.Entities, networkDate: Date) -> [TweetEntitiesMention.Property] {
        var properties: [TweetEntitiesMention.Property] = []
        if let userMentions = entities.userMentions {
            let newProperties = userMentions.compactMap { userMention -> TweetEntitiesMention.Property? in
                guard let indices = userMention.indices, indices.count == 2 else { return nil }
                return TweetEntitiesMention.Property(start: indices[0], end: indices[1], username: userMention.screenName)
            }
            properties.append(contentsOf: newProperties)
        }
        return properties
    }
}

extension TweetEntitiesMention.Property {
    static func properties(from entities: Twitter.Entity.V2.Entities, networkDate: Date) -> [TweetEntitiesMention.Property] {
        var properties: [TweetEntitiesMention.Property] = []
        if let mentions = entities.mentions {
            let newProperties = mentions.compactMap { mention -> TweetEntitiesMention.Property? in
                return TweetEntitiesMention.Property(start: mention.start, end: mention.end, username: mention.username)
            }
            properties.append(contentsOf: newProperties)
        }
        return properties
    }
}
