//
//  APIService+Timeline.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import DateToolsSwift
import TwitterAPI

extension APIService {
    
    static let homeTimelineRequestWindowInSec: TimeInterval = 15 * 60
    
    // incoming tweet - retweet relationship could be:
    // A1. incoming tweet NOT in local timeline, retweet NOT  in local (never see tweet and retweet)
    // A2. incoming tweet NOT in local timeline, retweet      in local (never see tweet but saw retweet before)
    // A3. incoming tweet     in local timeline, retweet MUST in local (saw tweet before)
    func twitterHomeTimeline(twitterAuthentication authentication: TwitterAuthentication) -> AnyPublisher<Twitter.Response<[Twitter.Entity.Tweet]>, Error> {
        let authorization = Twitter.API.OAuth.Authorization(
            consumerKey: authentication.consumerKey,
            consumerSecret: authentication.consumerSecret,
            accessToken: authentication.accessToken,
            accessTokenSecret: authentication.accessTokenSecret
        )
        
        // throttle request for API limit
        guard homeTimelineRequestThrottler.available(windowSizeInSec: APIService.homeTimelineRequestWindowInSec) else {
            return Fail(error: APIError.requestThrottle)
                .delay(for: .milliseconds(Int.random(in: 200..<1000)), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
                
        os_log("%{public}s[%{public}ld], %{public}s: fetch home timeline…", ((#file as NSString).lastPathComponent), #line, #function)
        return Twitter.API.Timeline.homeTimeline(session: session, authorization: authorization)
            .handleEvents(receiveOutput: { [weak self] response in
                guard let self = self else { return }
                
                let log = OSLog.api
                // update throttler
                if let responseTime = response.responseTime {
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: response cost %{public}ldms", ((#file as NSString).lastPathComponent), #line, #function, responseTime)
                }
                if let date = response.date, let rateLimit = response.rateLimit {
                    let currentTimeInterval = CACurrentMediaTime()
                    let responseNetworkDate = date
                    let resetTimeInterval = rateLimit.reset.timeIntervalSince(responseNetworkDate)
                    let resetAtTimeInterval = currentTimeInterval + resetTimeInterval
                    
                    self.homeTimelineRequestThrottler.rateLimit = APIService.RequestThrottler.RateLimit(
                        limit: rateLimit.limit,
                        remaining: rateLimit.remaining,
                        resetAt: resetAtTimeInterval
                    )
                    
                    let resetTimeIntervalInMin = resetTimeInterval / 60.0
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: API rate limit: %{public}ld/%{public}ld, reset at %{public}s, left: %.2fm (%.2fs)", ((#file as NSString).lastPathComponent), #line, #function, rateLimit.remaining, rateLimit.limit, rateLimit.reset.debugDescription, resetTimeIntervalInMin, resetTimeInterval)
                }
                
                // switch to background context
                self.backgroundManagedObjectContext.perform { [weak self] in
                    guard let self = self else { return }
                    let contextTaskSignpostID = OSSignpostID(log: log)
                    os_signpost(.begin, log: log, name: #function, signpostID: contextTaskSignpostID)
                    
                    let tweets = response.value
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: fetch %{public}ld tweets", ((#file as NSString).lastPathComponent), #line, #function, tweets.count)
                    
                    // load working set into context to avoid cache miss
                    let cacheTaskSignpostID = OSSignpostID(log: log)
                    os_signpost(.begin, log: log, name: "load tweets into cache", signpostID: cacheTaskSignpostID)
                    let workingIDRecord = APIService.WorkingIDRecord.workingID(entities: tweets)
                    
                    // contains retweet and quote
                    let _tweetCache: [Tweet] = {
                        let request = Tweet.sortedFetchRequest
                        let idStrSet = workingIDRecord.timelineTweetIDSet
                            .union(workingIDRecord.retweetIDSet)
                            .union(workingIDRecord.quoteIDSet)
                        let idStrs = Array(idStrSet)
                        request.predicate = Tweet.predicate(idStrs: idStrs)
                        request.returnsObjectsAsFaults = false
                        request.relationshipKeyPathsForPrefetching = [#keyPath(Tweet.retweet), #keyPath(Tweet.quote)]
                        do {
                            return try self.backgroundManagedObjectContext.fetch(request)
                        } catch {
                            assertionFailure(error.localizedDescription)
                            return []
                        }
                    }()
                    os_signpost(.event, log: log, name: "load tweets into cache", signpostID: cacheTaskSignpostID, "cached %{public}ld tweets", _tweetCache.count)
                    
                    //let _twitterUserCache: [TwitterUser] = {
                    //    let request = TwitterUser.sortedFetchRequest
                    //    let idStrs = Array(targetIDSet.map { $0.twitterUserID })
                    //    request.predicate = TwitterUser.predicate(idStrs: idStrs)
                    //    request.returnsObjectsAsFaults = false
                    //    do {
                    //        return try self.backgroundManagedObjectContext.fetch(request)
                    //    } catch {
                    //        assertionFailure(error.localizedDescription)
                    //        return []
                    //    }
                    //}()
                    //os_signpost(.event, log: log, name: "load twitter usrs into cache", signpostID: cacheTaskSignpostID, "cached %{public}ld twitter users", _twitterUserCache.count)
                    os_signpost(.end, log: log, name: "load tweets into cache", signpostID: cacheTaskSignpostID)

                    let cachedTweetsInTimeline = _tweetCache.filter { tweet in
                        workingIDRecord.timelineTweetIDSet.contains(tweet.idStr)
                    }
                    
                    let updateDatabaseTaskSignpostID = OSSignpostID(log: log)
                    var newTweets: [Tweet] = []
                    let workingChangeRecord = WorkingChangeRecord()
                    os_signpost(.begin, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
                    for entity in tweets {
                        let processEntityTaskSignpostID = OSSignpostID(log: log)
                        os_signpost(.begin, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "process entity %{public}s", entity.idStr)
                        defer {
                            os_signpost(.end, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "process entity %{public}s", entity.idStr)
                        }
                        
                        let timelineIndexProperty = TimelineIndex.Property(userID: entity.user.idStr, platform: .twitter, createdAt: entity.createdAt)
                        let timelineIndex = TimelineIndex.insert(into: self.backgroundManagedObjectContext, property: timelineIndexProperty)
                            os_signpost(.event, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "did insert new timelineIndex %{public}s", timelineIndex.id.uuidString)
                        let tweet = APIService.createOrMergeTweet(into: self.backgroundManagedObjectContext, entity: entity, timelineIndex: timelineIndex, networkDate: response.networkDate, log: log, workingChangeRecord: workingChangeRecord)
                        newTweets.append(tweet)
                    }   // end for…
                    os_signpost(.end, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
                    
                    // TODO:
                    if cachedTweetsInTimeline.isEmpty {
                        // may have gap, set oldest tweet has more
                        newTweets.sort(by: { $0.createdAt < $1.createdAt })
                        newTweets.first.flatMap { $0.update(hasMore: true) }
                    }
                    
                    do {
                        try self.backgroundManagedObjectContext.saveOrRollback()
                        os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: database updated", ((#file as NSString).lastPathComponent), #line, #function)
                        
                        let newTweetCount = workingChangeRecord.newTweetIDSet.count
                        let oldTweetCount = workingChangeRecord.oldTweetIDSet.count
                        
                        let newTweetIDStrs = newTweets.map { $0.idStr }
                        let newTweetInTimelineCount = workingChangeRecord.newTweetIDSet.filter { newTweetIDStrs.contains($0) }.count
                        os_log(.debug, log: log, "%{public}s[%{public}ld], %{public}s: create %{public}ld tweets, merge %{public}ld tweets, new %{public}ld tweets in timeline", ((#file as NSString).lastPathComponent), #line, #function, newTweetCount, oldTweetCount, newTweetInTimelineCount)
                    } catch {
                        os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: database update fail. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        assertionFailure(error.localizedDescription)
                    }
                    os_signpost(.end, log: .api, name: #function, signpostID: contextTaskSignpostID)
                }   // end perform
            })
            .eraseToAnyPublisher()
    }
    
}

extension APIService {
    private struct WorkingIDRecord {
        var timelineTweetIDSet: Set<String>
        var retweetIDSet: Set<String>
        var quoteIDSet: Set<String>
        var twitterUserIDSet: Set<String>
        
        enum RecordType {
            case timeline
            case retweet
            case quote
        }
        
        init() {
            self.init(
                timelineTweetIDSet: Set(),
                retweetIDSet: Set(),
                quoteIDSet: Set(),
                twitterUserIDSet: Set()
            )
        }
        
        init(timelineTweetIDSet: Set<String>, retweetIDSet: Set<String>, quoteIDSet: Set<String>, twitterUserIDSet: Set<String>) {
            self.timelineTweetIDSet = timelineTweetIDSet
            self.retweetIDSet = retweetIDSet
            self.quoteIDSet = quoteIDSet
            self.twitterUserIDSet = twitterUserIDSet
        }
        
        mutating func union(record: WorkingIDRecord) {
            timelineTweetIDSet = timelineTweetIDSet.union(record.timelineTweetIDSet)
            retweetIDSet = retweetIDSet.union(record.retweetIDSet)
            quoteIDSet = quoteIDSet.union(record.quoteIDSet)
            twitterUserIDSet = twitterUserIDSet.union(record.twitterUserIDSet)
        }
        
        static func workingID(entities: [Twitter.Entity.Tweet]) -> WorkingIDRecord {
            var value = WorkingIDRecord()
            for entity in entities {
                let child = workingID(entity: entity, recordType: .timeline)
                value.union(record: child)
            }
            return value
        }
        
        private static func workingID(entity: Twitter.Entity.Tweet, recordType: RecordType) -> WorkingIDRecord {
            var value = WorkingIDRecord()
            switch recordType {
            case .timeline: value.timelineTweetIDSet = Set([entity.idStr])
            case .retweet:  value.retweetIDSet = Set([entity.idStr])
            case.quote:     value.quoteIDSet = Set([entity.idStr])
            }
            value.twitterUserIDSet = Set([entity.user.idStr])
            
            if let retweetedStatus = entity.retweetedStatus {
                let child = workingID(entity: retweetedStatus, recordType: .retweet)
                value.union(record: child)
            }
            if let quotedStatus = entity.quotedStatus {
                let child = workingID(entity: quotedStatus, recordType: .quote)
                value.union(record: child)
            }
            return value
        }
    }
    
    private class WorkingChangeRecord {
        var newTweetIDSet: Set<String> = Set()
        var oldTweetIDSet: Set<String> = Set()
        var newTwitterUserIDSet: Set<String> = Set()
        var oldTwitterUserIDSet: Set<String> = Set()
        
        func isTracking(_ id: String) -> Bool {
            return newTweetIDSet.contains(id) || oldTweetIDSet.contains(id) || newTwitterUserIDSet.contains(id) || oldTwitterUserIDSet.contains(id)
        }
    }
    
    private static func createOrMergeTweet(
        into managedObjectContext: NSManagedObjectContext,
        entity: Twitter.Entity.Tweet,
        timelineIndex: TimelineIndex?,
        networkDate: Date,
        log: OSLog,
        workingChangeRecord: WorkingChangeRecord
    ) -> Tweet {
        let processEntityTaskSignpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "update database - process entity: createorMergeTweet", signpostID: processEntityTaskSignpostID, "process tweet %{public}s", entity.idStr)
        defer {
            os_signpost(.end, log: log, name: "update database - process entity: createorMergeTweet", signpostID: processEntityTaskSignpostID, "finish process tweet %{public}s", entity.idStr)
        }
        
        // fetch old tweet (should not has cache miss)
        let oldTweet: Tweet? = {
            let request = Tweet.sortedFetchRequest
            request.predicate = Tweet.predicate(idStr: entity.idStr)
            request.returnsObjectsAsFaults = false
            request.relationshipKeyPathsForPrefetching = [#keyPath(Tweet.retweet), #keyPath(Tweet.quote)]
            do {
                return try managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()
        
        if let oldTweet = oldTweet {
            // merge old tweet
            defer {
                APIService.mergeTweet(old: oldTweet, entity: entity, networkDate: networkDate)
            }
            
            if oldTweet.timelineIndex == nil {
                // entity not in timeline but contained by other local entity's retweet/quote
                os_signpost(.event, log: log, name: "update database - process entity: createorMergeTweet", signpostID: processEntityTaskSignpostID, "find old retweet %{public}s", entity.idStr)
                let timelineIndexProperty = TimelineIndex.Property(userID: entity.user.idStr, platform: .twitter, createdAt: entity.createdAt)
                let timelineIndex = TimelineIndex.insert(into: managedObjectContext, property: timelineIndexProperty)
                // make it indexed
                oldTweet.update(timelineIndex: timelineIndex)
            } else {
                os_signpost(.event, log: log, name: "update database - process entity: createorMergeTweet", signpostID: processEntityTaskSignpostID, "find old tweet %{public}s", entity.idStr)
            }
            
            if !workingChangeRecord.isTracking(oldTweet.idStr) {
                workingChangeRecord.oldTweetIDSet.insert(oldTweet.idStr)
            }
            return oldTweet
        } else {
            // create new tweet
            let tweetProperty = Tweet.Property(entity: entity, networkDate: networkDate)
            let retweet: Tweet? = entity.retweetedStatus.flatMap { entity -> Tweet in
                createOrMergeTweet(into: managedObjectContext, entity: entity, timelineIndex: nil, networkDate: networkDate, log: log, workingChangeRecord: workingChangeRecord)
            }
            let quote: Tweet? = entity.quotedStatus.flatMap { entity -> Tweet in
                createOrMergeTweet(into: managedObjectContext, entity: entity, timelineIndex: nil, networkDate: networkDate, log: log, workingChangeRecord: workingChangeRecord)
            }
            let twitterUser = createOrMergeTwitterUser(into: managedObjectContext, entity: entity.user, networkDate: networkDate, log: log)
            let tweet = Tweet.insert(into: managedObjectContext, property: tweetProperty, retweet: retweet, quote: quote, twitterUser: twitterUser, timelineIndex: timelineIndex)
            
            if !workingChangeRecord.isTracking(tweet.idStr) {
                workingChangeRecord.newTweetIDSet.insert(tweet.idStr)
            }
            return tweet
        }
    }
    
    private static func createOrMergeTwitterUser(
        into managedObjectContext: NSManagedObjectContext,
        entity: Twitter.Entity.User,
        networkDate: Date,
        log: OSLog
    ) -> TwitterUser {
        let processEntityTaskSignpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "process twitter user %{public}s", entity.idStr)
        defer {
            os_signpost(.end, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "process twitter user %{public}s", entity.idStr)
        }
        
        // fetch old tweet (should not has cache miss)
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
            APIService.mergeTwitterUser(old: oldTwitterUser, entity: entity, networkDate: networkDate)
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "find old twitter user %{public}s: name %s", entity.idStr, oldTwitterUser.name ?? "<nil>")
            return oldTwitterUser
        } else {
            let twitterUserProperty = TwitterUser.Property(entity: entity, networkDate: networkDate)
            let twitterUser = TwitterUser.insert(into: managedObjectContext, property: twitterUserProperty)
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "did insert new twitter user %{public}s: name %s", twitterUser.id.uuidString, twitterUserProperty.name ?? "<nil>")
            return twitterUser
        }
    }
    
    private static func mergeTweet(old tweet: Tweet, entity: Twitter.Entity.Tweet, networkDate: Date) {
        guard networkDate > tweet.updatedAt else { return }
        
        // merge attributes
        tweet.update(text: entity.text)
        tweet.update(retweetCount: entity.retweetCount)
        tweet.update(favoriteCount: entity.favoriteCount)
        entity.retweeted.flatMap { tweet.update(retweeted: $0) }
        entity.favorited.flatMap { tweet.update(favorited: $0) }
        
        // set updateAt
        tweet.didUpdate(at: networkDate)

        // merge user
        mergeTwitterUser(old: tweet.user, entity: entity.user, networkDate: networkDate)
        
        // merge indirect retweet & quote
        if let retweet = tweet.retweet, let retweetedStatus = entity.retweetedStatus {
            mergeTweet(old: retweet, entity: retweetedStatus, networkDate: networkDate)
        }
        if let quote = tweet.quote, let quotedStatus = entity.quotedStatus {
            mergeTweet(old: quote, entity: quotedStatus, networkDate: networkDate)
        }
    }
    
    private static func mergeTwitterUser(old user: TwitterUser, entity: Twitter.Entity.User, networkDate: Date) {
        guard networkDate > user.updatedAt else { return }
        // only fulfill API supported fields
        entity.name.flatMap { user.update(name: $0) }
        entity.screenName.flatMap { user.update(screenName: $0) }
        entity.profileImageURLHTTPS.flatMap { user.update(profileImageURLHTTPS: $0) }
        // TODO: merge more fileds
    }
    
}
