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
        let media: [Twitter.Entity.V2.Media]?
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
        let replyTo = repliedToInfo.flatMap { info -> Tweet in
            let (tweet, _, _) = createOrMergeTweet(into: managedObjectContext, for: requestTwitterUser, info: info, repliedToInfo: nil, retweetedInfo: nil, quotedInfo: nil, networkDate: networkDate, log: log)
            return tweet
        }
        let retweet = retweetedInfo.flatMap { info -> Tweet in
            let (tweet, _, _) = createOrMergeTweet(into: managedObjectContext, for: requestTwitterUser, info: info, repliedToInfo: nil, retweetedInfo: nil, quotedInfo: quotedInfo, networkDate: networkDate, log: log)
            return tweet
        }
        let quote: Tweet? = {
            guard retweet == nil else { return nil }
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
            let (twitterUser, isTwitterUserCreated) = createOrMergeTwitterUser(into: managedObjectContext, for: requestTwitterUser, user: info.user, networkDate: networkDate, log: log)
            
            let media: [TwitterMedia]? = {
                guard let media = info.media else { return nil }
                let result = media.enumerated().compactMap { i, media -> TwitterMedia? in
                    let property = TwitterMedia.Property(index: i, id: nil, mediaKey: media.mediaKey, type: media.type, height: media.height, width: media.width, durationMS: media.durationMS, url: media.url, previewImageURL: media.previewImageURL)
                    let metrics: TwitterMediaMetrics? = {
                        return media.publicMetrics.flatMap { publicMetrics in
                            let property = TwitterMediaMetrics.Property(viewCount: publicMetrics.viewCount)
                            return TwitterMediaMetrics.insert(into: managedObjectContext, property: property)
                        }
                    }()
                    return TwitterMedia.insert(into: managedObjectContext, property: property, metrics: metrics)
                }
                guard !result.isEmpty else { return nil }
                return result
            }()
            let entities: TweetEntities? = {
                guard let urlEntities = info.tweet.entities?.urls else { return nil }
                let properties = urlEntities.compactMap { urlEntity -> TweetEntitiesURL.Property? in
                    let property = TweetEntitiesURL.Property(start: urlEntity.start, end: urlEntity.end, url: urlEntity.url, expandedURL: urlEntity.expandedURL, displayURL: urlEntity.displayURL, unwoundURL: urlEntity.unwoundURL, networkDate: networkDate)
                    return property
                }
                let urls = properties.map { property in
                    return TweetEntitiesURL.insert(into: managedObjectContext, property: property)
                }
                guard !urls.isEmpty else { return nil }
                let entities = TweetEntities.insert(into: managedObjectContext, urls: urls)
                return entities
            }()
            let metrics: TweetMetrics? = {
                guard let publicMetrics = info.tweet.publicMetrics else { return nil }
                guard publicMetrics.likeCount > 0 || publicMetrics.quoteCount > 0 || publicMetrics.replyCount > 0 || publicMetrics.retweetCount > 0 else { return nil }
                let metricsProperty = TweetMetrics.Property(likeCount: publicMetrics.likeCount, quoteCount: publicMetrics.quoteCount, replyCount: publicMetrics.replyCount, retweetCount: publicMetrics.retweetCount)
                let metrics = TweetMetrics.insert(into: managedObjectContext, property: metricsProperty)
                return metrics
            }()
            let place: TwitterPlace? = {
                // guard let place = info.place else { return nil }
                // let placeProperty = TwitterPlace
                return nil
            }()
            
            let tweetProperty = Tweet.Property(entity: info.tweet, replyToTweetID: repliedToInfo?.tweet.id, networkDate: networkDate)
            let tweet = Tweet.insert(
                into: managedObjectContext,
                property: tweetProperty,
                author: twitterUser,
                media: media,
                entities: entities,
                metrics: metrics,
                place: place,
                retweet: retweet,
                quote: quote,
                replyTo: replyTo,
                timelineIndex: nil,
                likeBy: nil,
                retweetBy: nil
            )
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTweet", signpostID: processEntityTaskSignpostID, "did insert new tweet %{public}s: %s", tweet.identifier.uuidString, info.tweet.id)
            return (tweet, true, isTwitterUserCreated)
        }
    }
    
    static func mergeTweet(for requestTwitterUser: TwitterUser?, old tweet: Tweet, info: TwitterInfo, networkDate: Date) {
        guard networkDate > tweet.updatedAt else { return }
        // merge attributes
//        tweet.update(place: entity.place)
        tweet.setupMetricsIfNeeds()
        info.tweet.publicMetrics.flatMap { tweet.metrics?.update(likeCount: $0.likeCount) }
        info.tweet.publicMetrics.flatMap { tweet.metrics?.update(retweetCount: $0.retweetCount) }
        info.tweet.publicMetrics.flatMap { tweet.metrics?.update(replyCount: $0.replyCount) }
        info.tweet.publicMetrics.flatMap { tweet.metrics?.update(quoteCount: $0.quoteCount) }
        
        // relationship with requestTwitterUser

        // set updateAt
        tweet.didUpdate(at: networkDate)
        
        // merge user
        mergeTwitterUser(for: requestTwitterUser, old: tweet.author, entity: info.user, networkDate: networkDate)
    }
    
}
