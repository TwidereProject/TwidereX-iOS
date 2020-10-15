//
//  APIService+CoreData.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-28.
//

import Foundation
import CoreData
import CoreDataStack
import CommonOSLog
import TwitterAPI

extension APIService {
    
    static func createOrMergeTwitterUser(
        into managedObjectContext: NSManagedObjectContext,
        for requestTwitterUser: TwitterUser?,
        entity: Twitter.Entity.User,
        networkDate: Date,
        log: OSLog
    ) -> (user: TwitterUser, isCreated: Bool) {
        let processEntityTaskSignpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "process twitter user %{public}s", entity.idStr)
        defer {
            os_signpost(.end, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "process twitter user %{public}s", entity.idStr)
        }
        
        // fetch old twitter user
        let oldTwitterUser: TwitterUser? = {
            let request = TwitterUser.sortedFetchRequest
            request.predicate = TwitterUser.predicate(idStr: entity.idStr)
            request.returnsObjectsAsFaults = false
            do {
                return try managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()
        
        if let oldTwitterUser = oldTwitterUser {
            // merge old twitter usre
            APIService.mergeTwitterUser(for: requestTwitterUser, old: oldTwitterUser, entity: entity, networkDate: networkDate)
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "find old twitter user %{public}s: name %s", entity.idStr, oldTwitterUser.name ?? "<nil>")
            return (oldTwitterUser, false)
        } else {
            let twitterUserProperty = TwitterUser.Property(entity: entity, networkDate: networkDate)
            let twitterUser = TwitterUser.insert(
                into: managedObjectContext,
                property: twitterUserProperty,
                following: (entity.following ?? false) ? requestTwitterUser : nil,
                followRequestSent: (entity.followRequestSent ?? false) ? requestTwitterUser : nil
            )
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "did insert new twitter user %{public}s: name %s", twitterUser.id.uuidString, twitterUserProperty.name ?? "<nil>")
            return (twitterUser, true)
        }
    }
    
    static func createOrMergeTweet(
        into managedObjectContext: NSManagedObjectContext,
        for requestTwitterUser: TwitterUser?,
        entity: Twitter.Entity.Tweet,
        networkDate: Date,
        log: OSLog
    ) -> (user: Tweet, isTweetCreated: Bool, isTwitterUserCreated: Bool) {
        let processEntityTaskSignpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "update database - process entity: createOrMergeTwitter", signpostID: processEntityTaskSignpostID, "process twitter user %{public}s", entity.idStr)
        defer {
            os_signpost(.end, log: log, name: "update database - process entity: createOrMergeTwitter", signpostID: processEntityTaskSignpostID, "process twitter user %{public}s", entity.idStr)
        }
        
        // build tree
        let retweet = entity.retweetedStatus.flatMap { entity -> Tweet in
            let (tweet, _, _) = createOrMergeTweet(into: managedObjectContext, for: requestTwitterUser, entity: entity, networkDate: networkDate, log: log)
            return tweet
        }
        let quote = entity.quotedStatus.flatMap { entity -> Tweet in
            let (tweet, _, _) = createOrMergeTweet(into: managedObjectContext, for: requestTwitterUser, entity: entity, networkDate: networkDate, log: log)
            return tweet
        }
        
        // fetch old tweet
        let oldTweet: Tweet? = {
            let request = Tweet.sortedFetchRequest
            request.predicate = Tweet.predicate(idStr: entity.idStr)
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
            APIService.mergeTweet(for: requestTwitterUser, old: oldTweet, entity: entity, networkDate: networkDate)
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTweet", signpostID: processEntityTaskSignpostID, "find old tweet %{public}s", entity.idStr)
            return (oldTweet, false, false)
        } else {
            let (twitterUser, isTwitterUserCreated) = createOrMergeTwitterUser(into: managedObjectContext, for: requestTwitterUser, entity: entity.user, networkDate: networkDate, log: log)
            
            let tweetProperty = Tweet.Property(entity: entity, networkDate: networkDate)
            let tweet = Tweet.insert(
                into: managedObjectContext,
                property: tweetProperty,
                retweet: retweet,
                quote: quote,
                twitterUser: twitterUser,
                timelineIndex: nil,
                likeBy: (entity.favorited ?? false) ? requestTwitterUser : nil,
                retweetBy: (entity.retweeted ?? false) ? requestTwitterUser : nil
            )
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTweet", signpostID: processEntityTaskSignpostID, "did insert new tweet %{public}s: %s", twitterUser.id.uuidString, entity.idStr)
            return (tweet, true, isTwitterUserCreated)
        }
    }
    
    static func mergeTweet(for requestTwitterUser: TwitterUser?, old tweet: Tweet, entity: Twitter.Entity.Tweet, networkDate: Date) {
        guard networkDate > tweet.updatedAt else { return }
        
        // merge attributes
        tweet.update(coordinates: entity.coordinates)
        tweet.update(place: entity.place)
        tweet.update(retweetCount: entity.retweetCount)
        tweet.update(favoriteCount: entity.favoriteCount)
        entity.quotedStatusIDStr.flatMap { tweet.update(quotedStatusIDStr: $0) }
        
        // relationship with requestTwitterUser
        if let requestTwitterUser = requestTwitterUser {
            entity.favorited.flatMap { tweet.update(favorited: $0, twitterUser: requestTwitterUser) }
            entity.retweeted.flatMap { tweet.update(retweeted: $0, twitterUser: requestTwitterUser) }
        }
        
        // set updateAt
        tweet.didUpdate(at: networkDate)
        
        // merge user
        mergeTwitterUser(for: requestTwitterUser, old: tweet.user, entity: entity.user, networkDate: networkDate)
        
        // merge indirect retweet & quote
        if let retweet = tweet.retweet, let retweetedStatus = entity.retweetedStatus {
            mergeTweet(for: requestTwitterUser, old: retweet, entity: retweetedStatus, networkDate: networkDate)
        }
        if let quote = tweet.quote, let quotedStatus = entity.quotedStatus {
            mergeTweet(for: requestTwitterUser, old: quote, entity: quotedStatus, networkDate: networkDate)
        }
    }
    
    static func mergeTwitterUser(for requestTwitterUser: TwitterUser?, old user: TwitterUser, entity: Twitter.Entity.User, networkDate: Date) {
        guard networkDate > user.updatedAt else { return }
        // only fulfill API supported fields
        entity.name.flatMap { user.update(name: $0) }
        entity.screenName.flatMap { user.update(screenName: $0) }
        entity.userDescription.flatMap { user.update(bioDescription: $0) }
        entity.url.flatMap { user.update(url: $0) }
        entity.location.flatMap { user.update(location: $0) }
        entity.protected.flatMap { user.update(protected: $0) }
        entity.friendsCount.flatMap { user.update(friendsCount: $0) }
        entity.followersCount.flatMap { user.update(followersCount: $0) }
        entity.listedCount.flatMap { user.update(listedCount: $0) }
        entity.favouritesCount.flatMap { user.update(favouritesCount: $0) }
        entity.statusesCount.flatMap { user.update(statusesCount: $0) }
        entity.profileImageURLHTTPS.flatMap { user.update(profileImageURLHTTPS: $0) }
        entity.profileBannerURL.flatMap { user.update(profileBannerURL: $0) }
        
        // relationship with requestTwitterUser
        if let requestTwitterUser = requestTwitterUser {
            entity.following.flatMap { user.update(following: $0, twitterUser: requestTwitterUser) }
            entity.followRequestSent.flatMap { user.update(followRequestSent: $0, twitterUser: requestTwitterUser) }
        }
        // TODO: merge more fileds
        
        
        user.didUpdate(at: networkDate)
    }
    
}
