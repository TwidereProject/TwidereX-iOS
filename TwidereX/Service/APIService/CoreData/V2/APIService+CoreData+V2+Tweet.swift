//
//  APIService+CoreData+V2+Tweet.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-19.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack
import CommonOSLog
import TwitterAPI

extension APIService.CoreData.V2 {
    
    struct TwitterInfo {
        let tweet: Twitter.Entity.V2.Tweet
        let user: Twitter.Entity.V2.User
    }
    
    static func createOrMergeTweet(
        into managedObjectContext: NSManagedObjectContext,
        for requestTwitterUser: TwitterUser?,
        info: TwitterInfo,
        repliedToInfo: TwitterInfo?,
        retweetedInfo: TwitterInfo?,
        quotedInfo: TwitterInfo?,
        networkDate: Date,
        log: OSLog
    ) -> (twwet: Tweet, isTweetCreated: Bool, isTwitterUserCreated: Bool) {
        let processEntityTaskSignpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "update database - process entity: createOrMergeTweet", signpostID: processEntityTaskSignpostID, "process tweet %{public}s", info.tweet.id)
        defer {
            os_signpost(.end, log: log, name: "update database - process entity: createOrMergeTwitter", signpostID: processEntityTaskSignpostID, "process tweet %{public}s", info.tweet.id)
        }
        
        // build tree
        let repliedTo = repliedToInfo.flatMap { info -> Tweet in
            let (tweet, _, _) = createOrMergeTweet(into: managedObjectContext, for: requestTwitterUser, info: info, repliedToInfo: nil, retweetedInfo: nil, quotedInfo: nil, networkDate: networkDate, log: log)
            return tweet
        }
        let retweeted = retweetedInfo.flatMap { info -> Tweet in
            let (tweet, _, _) = createOrMergeTweet(into: managedObjectContext, for: requestTwitterUser, info: info, repliedToInfo: nil, retweetedInfo: nil, quotedInfo: quotedInfo, networkDate: networkDate, log: log)
            return tweet
        }
        let quoted: Tweet? = {
            guard retweeted == nil else { return nil }
            return quotedInfo.flatMap { info -> Tweet in
                let (tweet, _, _) = createOrMergeTweet(into: managedObjectContext, for: requestTwitterUser, info: info, repliedToInfo: nil, retweetedInfo: nil, quotedInfo: nil, networkDate: networkDate, log: log)
                return tweet
            }
        }()

        // fetch old tweet
        let oldTweet: Tweet? = {
            let request = Tweet.sortedFetchRequest
            request.predicate = Tweet.predicate(idStr: info.tweet.id)
            request.returnsObjectsAsFaults = false
            do {
                return try managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()

        if let oldTweet = oldTweet {
            // merge old tweet
            APIService.CoreData.V2.mergeTweet(for: requestTwitterUser, old: oldTweet, info: info, networkDate: networkDate)
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTweet", signpostID: processEntityTaskSignpostID, "find old tweet %{public}s", info.tweet.id)
            return (oldTweet, false, false)
        } else {
            fatalError()
//            let (twitterUser, isTwitterUserCreated) = createOrMergeTwitterUser(into: managedObjectContext, for: requestTwitterUser, entity: entity.user, networkDate: networkDate, log: log)
//
//            let tweetProperty = Tweet.Property(entity: entity, networkDate: networkDate)
//            let tweet = Tweet.insert(
//                into: managedObjectContext,
//                property: tweetProperty,
//                retweet: retweet,
//                quote: quote,
//                twitterUser: twitterUser,
//                timelineIndex: nil,
//                likeBy: (entity.favorited ?? false) ? requestTwitterUser : nil,
//                retweetBy: (entity.retweeted ?? false) ? requestTwitterUser : nil
//            )
//            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTweet", signpostID: processEntityTaskSignpostID, "did insert new tweet %{public}s: %s", twitterUser.id.uuidString, entity.idStr)
//            return (tweet, true, isTwitterUserCreated)
        }
    }
    
    static func mergeTweet(for requestTwitterUser: TwitterUser?, old tweet: Tweet, info: TwitterInfo, networkDate: Date) {
        guard networkDate > tweet.updatedAt else { return }
        // TODO:
        print("merge tweet \(info.tweet.id)")
        // merge attributes
//        tweet.update(coordinates: entity.coordinates)
//        tweet.update(place: entity.place)
//        tweet.update(retweetCount: entity.retweetCount)
//        tweet.update(favoriteCount: entity.favoriteCount)
//        entity.quotedStatusIDStr.flatMap { tweet.update(quotedStatusIDStr: $0) }
        
        // relationship with requestTwitterUser
//        if let requestTwitterUser = requestTwitterUser {
//            entity.favorited.flatMap { tweet.update(favorited: $0, twitterUser: requestTwitterUser) }
//            entity.retweeted.flatMap { tweet.update(retweeted: $0, twitterUser: requestTwitterUser) }
//        }
//
        // set updateAt
//        tweet.didUpdate(at: networkDate)
        
        // merge user
//        mergeTwitterUser(for: requestTwitterUser, old: tweet.user, entity: entity.user, networkDate: networkDate)
        
        // merge indirect retweet & quote
//        if let retweet = tweet.retweet, let retweetedStatus = entity.retweetedStatus {
//            mergeTweet(for: requestTwitterUser, old: retweet, entity: retweetedStatus, networkDate: networkDate)
//        }
//        if let quote = tweet.quote, let quotedStatus = entity.quotedStatus {
//            mergeTweet(for: requestTwitterUser, old: quote, entity: quotedStatus, networkDate: networkDate)
//        }
    }
    
}
