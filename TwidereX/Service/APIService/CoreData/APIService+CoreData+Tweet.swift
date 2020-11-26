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

extension APIService.CoreData {
    
    static func createOrMergeTweet(
        into managedObjectContext: NSManagedObjectContext,
        for requestTwitterUser: TwitterUser?,
        entity: Twitter.Entity.Tweet,
        networkDate: Date,
        log: OSLog
    ) -> (tweet: Tweet, isTweetCreated: Bool, isTwitterUserCreated: Bool) {
        let processEntityTaskSignpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "update database - process entity: createOrMergeTweet", signpostID: processEntityTaskSignpostID, "process tweet %{public}s", entity.idStr)
        defer {
            os_signpost(.end, log: log, name: "update database - process entity: createOrMergeTweet", signpostID: processEntityTaskSignpostID, "process tweet %{public}s", entity.idStr)
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
            APIService.CoreData.mergeTweet(for: requestTwitterUser, old: oldTweet, entity: entity, networkDate: networkDate)
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTweet", signpostID: processEntityTaskSignpostID, "find old tweet %{public}s", entity.idStr)
            return (oldTweet, false, false)
        } else {
            let (twitterUser, isTwitterUserCreated) = createOrMergeTwitterUser(into: managedObjectContext, for: requestTwitterUser, entity: entity.user, networkDate: networkDate, log: log)
            
            let media: [TwitterMedia]? = {
                guard let media = entity.extendedEntities?.media else { return nil }
                let result = media.enumerated().compactMap { i, media -> TwitterMedia? in
                    guard let idStr = media.idStr, let type = media.type else {
                        assertionFailure()
                        return nil
                    }
                    let size = media.sizes?.large
                    let property = TwitterMedia.Property(index: i, id: idStr, mediaKey: idStr, type: type, height: size?.h, width: size?.w, durationMS: nil, url: media.mediaURLHTTPS, previewImageURL: nil)
                    return TwitterMedia.insert(into: managedObjectContext, property: property, metrics: nil)
                }
                guard !result.isEmpty else { return nil }
                return result
            }()
            let entities: TweetEntities? = {
                let urls: [TweetEntitiesURL] = {
                    var urls: [TweetEntitiesURL] = []
                    if let urlEntities = entity.entities.urls {
                        let properties = urlEntities.compactMap { urlEntity -> TweetEntitiesURL.Property? in
                            guard let indices = urlEntity.indices, indices.count == 2 else { return nil }
                            let property = TweetEntitiesURL.Property(start: indices[0], end: indices[1], url: urlEntity.url, expandedURL: urlEntity.expandedURL, displayURL: urlEntity.displayURL, unwoundURL: nil, networkDate: networkDate)
                            return property
                        }
                        let newUrls = properties.map { property in
                            return TweetEntitiesURL.insert(into: managedObjectContext, property: property)
                        }
                        urls.append(contentsOf: newUrls)
                    }
                    if let mediaEntities = entity.extendedEntities?.media {
                        let properties = mediaEntities.compactMap { urlEntity -> TweetEntitiesURL.Property? in
                            guard let indices = urlEntity.indices, indices.count == 2 else { return nil }
                            let property = TweetEntitiesURL.Property(start: indices[0], end: indices[1], url: urlEntity.url, expandedURL: urlEntity.expandedURL, displayURL: urlEntity.displayURL, unwoundURL: nil, networkDate: networkDate)
                            return property
                        }
                        let newUrls = properties.map { property in
                            return TweetEntitiesURL.insert(into: managedObjectContext, property: property)
                        }
                        urls.append(contentsOf: newUrls)
                    }
                    return urls
                }()
                guard !urls.isEmpty else { return nil }
                let entities = TweetEntities.insert(into: managedObjectContext, urls: urls)
                return entities
            }()
            let metrics: TweetMetrics? = {
                guard (entity.favoriteCount ?? 0) > 0 || (entity.retweetCount ?? 0) > 0 else { return nil }
                let metricsProperty = TweetMetrics.Property(likeCount: entity.favoriteCount, quoteCount: nil, replyCount: nil, retweetCount: entity.retweetCount)
                let metrics = TweetMetrics.insert(into: managedObjectContext, property: metricsProperty)
                return metrics
            }()
            let place: TwitterPlace? = {
                guard let place = entity.place, let fullname = place.fullName else { return nil }
                let placeProperty = TwitterPlace.Property(id: place.id, fullname: fullname, county: place.country, countyCode: place.countryCode, name: place.name, placeType: place.placeType)
                return TwitterPlace.insert(into: managedObjectContext, property: placeProperty)
            }()
            
            let tweetProperty = Tweet.Property(entity: entity, networkDate: networkDate)
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
                replyTo: nil,
                timelineIndex: nil,
                likeBy: (entity.favorited ?? false) ? requestTwitterUser : nil,
                retweetBy: (entity.retweeted ?? false) ? requestTwitterUser : nil
            )
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTweet", signpostID: processEntityTaskSignpostID, "did insert new tweet %{public}s: %s", twitterUser.identifier.uuidString, entity.idStr)
            return (tweet, true, isTwitterUserCreated)
        }
    }
    
    static func mergeTweet(for requestTwitterUser: TwitterUser?, old tweet: Tweet, entity: Twitter.Entity.Tweet, networkDate: Date) {
        guard networkDate > tweet.updatedAt else { return }
        
        // merge place
        if tweet.place == nil,
           let place = entity.place,
           let fullname = place.fullName,
           let managedObjectContext = tweet.managedObjectContext
        {
            let placeProperty = TwitterPlace.Property(id: place.id, fullname: fullname, county: place.country, countyCode: place.countryCode, name: place.name, placeType: place.placeType)
            tweet.update(place: TwitterPlace.insert(into: managedObjectContext, property: placeProperty))
        }
        
        // media URL may change
        if let media = tweet.media {
            for newMedia in entity.extendedEntities?.media ?? [] {
                guard let id = newMedia.idStr else { continue }
                guard let targetMedia = media.first(where: { $0.id == id }) else { continue }
                targetMedia.update(url: newMedia.mediaURLHTTPS)
            }
        }
        
        // merge metrics
        tweet.setupMetricsIfNeeds()
        entity.favoriteCount.flatMap { tweet.metrics?.update(likeCount: $0) }
        entity.retweetCount.flatMap { tweet.metrics?.update(retweetCount: $0) }
        
        // relationship with requestTwitterUser
        if let requestTwitterUser = requestTwitterUser {
            entity.favorited.flatMap { tweet.update(liked: $0, twitterUser: requestTwitterUser) }
            entity.retweeted.flatMap { tweet.update(retweeted: $0, twitterUser: requestTwitterUser) }
        }
        
        // set updateAt
        tweet.didUpdate(at: networkDate)
        
        // merge user
        mergeTwitterUser(for: requestTwitterUser, old: tweet.author, entity: entity.user, networkDate: networkDate)
        
        // merge indirect retweet & quote
        if let retweet = tweet.retweet, let retweetedStatus = entity.retweetedStatus {
            mergeTweet(for: requestTwitterUser, old: retweet, entity: retweetedStatus, networkDate: networkDate)
        }
        if let quote = tweet.quote, let quotedStatus = entity.quotedStatus {
            mergeTweet(for: requestTwitterUser, old: quote, entity: quotedStatus, networkDate: networkDate)
        }
    }
    
}
