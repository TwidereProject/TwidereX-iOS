//
//  Persistence+Twitter.swift
//  Persistence+Twitter
//
//  Created by Cirno MainasuK on 2021-8-31.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import CoreData
import CoreDataStack
import TwitterSDK

extension Persistence.Twitter {
    
    struct PersistContextV2 {
        let dictionary: Twitter.Response.V2.DictContent
        let statusCache: APIService.Persist.PersistCache<TwitterStatus>?
        let userCache: APIService.Persist.PersistCache<TwitterUser>?
        let networkDate: Date
        let log = OSLog.api
    }
    
    static func persist(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContextV2
    ) {
        for status in context.dictionary.tweetDict.values {
            guard let authorID = status.authorID,
                  let author = context.dictionary.userDict[authorID]
            else { continue }
            
            var repost: Persistence.TwitterStatus.PersistContextV2.Entity?
            var replyTo: Persistence.TwitterStatus.PersistContextV2.Entity?
            var quote: Persistence.TwitterStatus.PersistContextV2.Entity?
            
            for referencedTweet in status.referencedTweets ?? [] {
                guard let type = referencedTweet.type,
                      let statusID = referencedTweet.id
                else { continue }
                guard let status = context.dictionary.tweetDict[statusID],
                      let authorID = status.authorID,
                      let author = context.dictionary.userDict[authorID]
                else { continue }
                let entity = Persistence.TwitterStatus.PersistContextV2.Entity(
                    status: status,
                    author: author
                )
                switch type {
                case .repliedTo:    replyTo = entity
                case .quoted:       quote = entity
                case .retweeted:    repost = entity
                }   // end switch
            }   // end for
            
            _ = Persistence.TwitterStatus.createOrMerge(
                in: managedObjectContext,
                context: Persistence.TwitterStatus.PersistContextV2(
                    entity: .init(status: status, author: author),
                    repost: repost,
                    quote: quote,
                    replyTo: replyTo,
                    dictionary: context.dictionary,
                    statusCache: nil, // TODO: context.statusCache,
                    userCache: nil, // TODO: context.userCache,
                    networkDate: context.networkDate
                )
            )   // end .createOrMerge(…)
        }   // end for
    }   // end func
}
