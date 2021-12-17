//
//  APIService+Persist+PersistCache.swift
//  TwidereX
//
//  Created by MainasuK Cirno on 2021-2-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import TwitterSDK

extension APIService.Persist {

    class PersistCache<T> {
        var dictionary: [String : T] = [:]
    }

}

extension APIService.Persist.PersistCache where T == Tweet {

    static func ids(for tweets: [Twitter.Entity.Tweet]) -> Set<Twitter.Entity.Tweet.ID> {
        var value = Set<String>()
        for tweet in tweets {
            value = value.union(ids(for: tweet))
        }
        return value
    }
    
    static func ids(for tweet: Twitter.Entity.Tweet) -> Set<Twitter.Entity.Tweet.ID> {
        var value = Set<String>()
        value.insert(tweet.idStr)
        if let retweet = tweet.retweetedStatus {
            value = value.union(ids(for: retweet))
        }
        if let quote = tweet.quotedStatus {
            value = value.union(ids(for: quote))
        }
        return value
    }
    
}

extension APIService.Persist.PersistCache where T == TwitterUser {

    static func ids(for tweets: [Twitter.Entity.Tweet]) -> Set<Twitter.Entity.User.ID> {
        var value = Set<String>()
        for tweet in tweets {
            value = value.union(ids(for: tweet))
        }
        return value
    }
    
    static func ids(for tweet: Twitter.Entity.Tweet) -> Set<Twitter.Entity.User.ID> {
        var value = Set<String>()
        value.insert(tweet.user.idStr)
        if let retweet = tweet.retweetedStatus {
            value = value.union(ids(for: retweet))
        }
        if let quote = tweet.quotedStatus {
            value = value.union(ids(for: quote))
        }
        return value
    }
    
}
