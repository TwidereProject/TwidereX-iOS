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
    
    public struct PersistContextV2 {
        public let dictionary: Twitter.Response.V2.DictContent
        public let user: TwitterUser?
        public let statusCache: Persistence.PersistCache<TwitterStatus>?
        public let userCache: Persistence.PersistCache<TwitterUser>?
        public let networkDate: Date
        public let log = OSLog.api
        
        public init(
            dictionary: Twitter.Response.V2.DictContent,
            user: TwitterUser?,
            statusCache: Persistence.PersistCache<TwitterStatus>?,
            userCache: Persistence.PersistCache<TwitterUser>?,
            networkDate: Date
        ) {
            self.dictionary = dictionary
            self.user = user
            self.statusCache = statusCache
            self.userCache = userCache
            self.networkDate = networkDate
        }
    }
    
    public static func persist(
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
                    user: context.user,
                    statusCache: context.statusCache,
                    userCache: context.userCache,
                    networkDate: context.networkDate
                )
            )   // end .createOrMerge(…)
        }   // end for
    }   // end func
}
