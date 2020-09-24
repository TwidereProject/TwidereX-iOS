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
    func twitterHomeTimeline(authorization: Twitter.API.OAuth.Authorization) -> AnyPublisher<Twitter.Response<[Twitter.Entity.Tweet]>, Error> {
        
        // throttle request for API limit
        guard homeTimelineRequestThrottler.available(windowSizeInSec: APIService.homeTimelineRequestWindowInSec) else {
            return Fail(error: APIError.requestThrottle)
                .delay(for: .milliseconds(Int.random(in: 200..<1000)), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
                
        os_log("%{public}s[%{public}ld], %{public}s: fetch home timeline…", ((#file as NSString).lastPathComponent), #line, #function)
        let query = Twitter.API.Timeline.Query(count: 200)
        return Twitter.API.Timeline.homeTimeline(session: session, authorization: authorization, query: query)
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
                    os_signpost(.end, log: log, name: "load tweets into cache", signpostID: cacheTaskSignpostID)
                                        
                    let updateDatabaseTaskSignpostID = OSSignpostID(log: log)
                    var workingRecords: [WorkingRecord] = []
                    os_signpost(.begin, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
                    for entity in tweets {
                        let processEntityTaskSignpostID = OSSignpostID(log: log)
                        os_signpost(.begin, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "process entity %{public}s", entity.idStr)
                        defer {
                            os_signpost(.end, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "process entity %{public}s", entity.idStr)
                        }
                        
                        let record = WorkingRecord.createOrMergeTweet(into: self.backgroundManagedObjectContext, entity: entity, recordType: .timeline, networkDate: response.networkDate, log: log)
                        workingRecords.append(record)
                    }   // end for…
                    os_signpost(.end, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
                    
                    let mergedOldTweetsInTimeline = workingRecords.filter { $0.tweetProcessType == .merge }
                    if mergedOldTweetsInTimeline.isEmpty {
                        // no overlap. may have gap so set oldest tweet hasMore
                        workingRecords
                            .map { $0.tweet }
                            .sorted(by: { $0.createdAt < $1.createdAt })
                            .first.flatMap { $0.update(hasMore: true) }
                    }
                    
                    do {
                        try self.backgroundManagedObjectContext.saveOrRollback()
                        os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: database updated", ((#file as NSString).lastPathComponent), #line, #function)
                        
                        // print working record tree map
                        #if DEBUG
                        let logs = workingRecords
                            .map { record in record.log() }
                            .joined(separator: "\n")
                        os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: working status: \n%s", ((#file as NSString).lastPathComponent), #line, #function, logs)
                        let counting = workingRecords
                            .map { record in record.count() }
                            .reduce(into: WorkingRecord.Counting(), { result, next in result = result + next })
                        os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: tweet: insert %{public}ld, merge %{public}ld(%{public}ld)", ((#file as NSString).lastPathComponent), #line, #function, counting.tweet.create, mergedOldTweetsInTimeline.count, counting.tweet.merge)
                        os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: twitter user: insert %{public}ld, merge %{public}ld", ((#file as NSString).lastPathComponent), #line, #function, counting.user.create, counting.user.merge)
                        #endif
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
    
    private class WorkingRecord {
        
        let tweet: Tweet
        let children: [WorkingRecord]
        let recordType: RecordType
        let tweetProcessType: ProcessType
        let userProcessType: ProcessType
        
        init(tweet: Tweet, children: [APIService.WorkingRecord], recordType: APIService.WorkingRecord.RecordType, tweetProcessType: ProcessType, userProcessType: ProcessType) {
            self.tweet = tweet
            self.children = children
            self.recordType = recordType
            self.tweetProcessType = tweetProcessType
            self.userProcessType = userProcessType
        }

        enum RecordType {
            case timeline       // a.k.a root
            case retweet
            case quote
            
            var flag: String {
                switch self {
                case .timeline: return "T"
                case .retweet:  return "R"
                case .quote:    return "Q"
                }
            }
        }
        
        enum ProcessType {
            case create
            case merge
            
            var flag: String {
                switch self {
                case .create:   return "+"
                case .merge:    return "-"
                }
            }
        }
        
        func log(indentLevel: Int = 0) -> String {
            let indent = Array(repeating: "    ", count: indentLevel).joined()
            let tweetPreview = tweet.text.prefix(32).replacingOccurrences(of: "\n", with: " ")
            let message = "\(indent)[\(tweetProcessType.flag)\(recordType.flag)](\(tweet.idStr)) [\(userProcessType.flag)](\(tweet.user.idStr))@\(tweet.user.name ?? "<nil>") ~> \(tweetPreview)"
            
            var childrenMessages: [String] = []
            for child in children {
                childrenMessages.append(child.log(indentLevel: indentLevel + 1))
            }
            let result = [[message] + childrenMessages]
                .flatMap { $0 }
                .joined(separator: "\n")
            
            return result
        }
        
        struct Counting {
            var tweet = Counter()
            var user = Counter()
            
            static func + (left: Counting, right: Counting) -> Counting {
                return Counting(
                    tweet: left.tweet + right.tweet,
                    user: left.user + right.user
                )
            }
            
            struct Counter {
                var create = 0
                var merge  = 0
                
                static func + (left: Counter, right: Counter) -> Counter {
                    return Counter(
                        create: left.create + right.create,
                        merge: left.merge + right.merge
                    )
                }
            }
        }
        
        func count() -> Counting {
            var counting = Counting()
            
            switch tweetProcessType {
            case .create:       counting.tweet.create += 1
            case .merge:        counting.tweet.merge += 1
            }
            
            switch userProcessType {
            case .create:       counting.user.create += 1
            case .merge:        counting.user.merge += 1
            }
            
            for child in children {
                let childCounting = child.count()
                counting = counting + childCounting
            }
         
            return counting
        }
        
        static func createOrMergeTweet(
            into managedObjectContext: NSManagedObjectContext,
            entity: Twitter.Entity.Tweet,
            recordType: RecordType,
            networkDate: Date,
            log: OSLog
        ) -> WorkingRecord {
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
            
            // build tree
            let retweetRecord: WorkingRecord? = entity.retweetedStatus.flatMap { entity -> WorkingRecord in
                createOrMergeTweet(into: managedObjectContext, entity: entity, recordType: .retweet, networkDate: networkDate, log: log)
            }
            let quoteRecord: WorkingRecord? = entity.quotedStatus.flatMap { entity -> WorkingRecord in
                createOrMergeTweet(into: managedObjectContext, entity: entity, recordType: .quote, networkDate: networkDate, log: log)
            }
            let children = [retweetRecord, quoteRecord].compactMap { $0 }
            
            if let oldTweet = oldTweet {
                // merge old tweet
                defer {
                    APIService.mergeTweet(old: oldTweet, entity: entity, networkDate: networkDate)
                }
                
                if recordType == .timeline {
                    // node is timeline
                    if oldTweet.timelineIndex == nil {
                        // exist tweet not in timeline and contained by other local entities' retweet/quote
                        os_signpost(.event, log: log, name: "update database - process entity: createorMergeTweet", signpostID: processEntityTaskSignpostID, "find old retweet %{public}s", entity.idStr)
                        let timelineIndexProperty = TimelineIndex.Property(userID: entity.user.idStr, platform: .twitter, createdAt: entity.createdAt)
                        let timelineIndex = TimelineIndex.insert(into: managedObjectContext, property: timelineIndexProperty)
                        // make it indexed
                        oldTweet.update(timelineIndex: timelineIndex)
                    } else {
                        // enity already in timeline
                    }
                } else {
                    os_signpost(.event, log: log, name: "update database - process entity: createorMergeTweet", signpostID: processEntityTaskSignpostID, "find old tweet %{public}s", entity.idStr)
                }
                
                return WorkingRecord(tweet: oldTweet, children: children, recordType: recordType, tweetProcessType: .merge, userProcessType: .merge)
            } else {
                // create new tweet
                let (twitterUser, isUserCreated) = createOrMergeTwitterUser(into: managedObjectContext, entity: entity.user, networkDate: networkDate, log: log)
                let timelineIndex: TimelineIndex? = {
                    guard recordType == .timeline else { return nil }
                    let timelineIndexProperty = TimelineIndex.Property(userID: entity.user.idStr, platform: .twitter, createdAt: entity.createdAt)
                    let timelineIndex = TimelineIndex.insert(into: managedObjectContext, property: timelineIndexProperty)
                    os_signpost(.event, log: log, name: "update database - process entity: createorMergeTweet", signpostID: processEntityTaskSignpostID, "did insert new timelineIndex %{public}s", timelineIndex.id.uuidString)
                    return timelineIndex
                }()                

                let tweetProperty = Tweet.Property(entity: entity, networkDate: networkDate)
                let tweet = Tweet.insert(into: managedObjectContext, property: tweetProperty, retweet: retweetRecord?.tweet, quote: quoteRecord?.tweet, twitterUser: twitterUser, timelineIndex: timelineIndex)
                
                return WorkingRecord(tweet: tweet, children: children, recordType: recordType, tweetProcessType: .create, userProcessType: isUserCreated ? .create : .merge)
            }
        }

    }
    
}

extension APIService {
    
    private static func createOrMergeTwitterUser(
        into managedObjectContext: NSManagedObjectContext,
        entity: Twitter.Entity.User,
        networkDate: Date,
        log: OSLog
    ) -> (user: TwitterUser, isCreated: Bool) {
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
            return (oldTwitterUser, false)
        } else {
            let twitterUserProperty = TwitterUser.Property(entity: entity, networkDate: networkDate)
            let twitterUser = TwitterUser.insert(into: managedObjectContext, property: twitterUserProperty)
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "did insert new twitter user %{public}s: name %s", twitterUser.id.uuidString, twitterUserProperty.name ?? "<nil>")
            return (twitterUser, true)
        }
    }
    
    private static func mergeTweet(old tweet: Tweet, entity: Twitter.Entity.Tweet, networkDate: Date) {
        guard networkDate > tweet.updatedAt else { return }
        
        // merge attributes
        tweet.update(coordinates: entity.coordinates)
        tweet.update(place: entity.place)
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
