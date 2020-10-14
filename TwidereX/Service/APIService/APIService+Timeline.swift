//
//  APIService+Timeline.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-30.
//

import os
import Foundation
import CoreData
import CoreDataStack
import CommonOSLog
import TwitterAPI

extension APIService {
    
    enum PersistTimelineType {
        case homeTimeline
        case userTimeline
    }
    
    static func persistTimeline(managedObjectContext: NSManagedObjectContext, query: Twitter.API.Timeline.Query, response: Twitter.Response<[Twitter.Entity.Tweet]>, persistType: PersistTimelineType, requestTwitterUserID: TwitterUser.UserID, log: OSLog) {
        
        let tweets = response.value
        os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: fetch %{public}ld tweets", ((#file as NSString).lastPathComponent), #line, #function, tweets.count)

        // switch to background context
        managedObjectContext.perform {
            let contextTaskSignpostID = OSSignpostID(log: log)
            os_signpost(.begin, log: log, name: #function, signpostID: contextTaskSignpostID)
            
            // load working set into context to avoid cache miss
            let cacheTaskSignpostID = OSSignpostID(log: log)
            os_signpost(.begin, log: log, name: "load tweets into cache", signpostID: cacheTaskSignpostID)
            let workingIDRecord = APIService.WorkingIDRecord.workingID(entities: tweets)
            
            let requestTwitterUser: TwitterUser? = {
                let request = TwitterUser.sortedFetchRequest
                request.predicate = TwitterUser.predicate(idStr: requestTwitterUserID)
                request.fetchLimit = 1
                request.returnsObjectsAsFaults = false
                do {
                    return try managedObjectContext.fetch(request).first
                } catch {
                    assertionFailure(error.localizedDescription)
                    return nil
                }
            }()
            
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
                    return try managedObjectContext.fetch(request)
                } catch {
                    assertionFailure(error.localizedDescription)
                    return []
                }
            }()
            os_signpost(.event, log: log, name: "load tweets into cache", signpostID: cacheTaskSignpostID, "cached %{public}ld tweets", _tweetCache.count)
            os_signpost(.end, log: log, name: "load tweets into cache", signpostID: cacheTaskSignpostID)
            
            // remote timeline merge local timeline record set
            // declare it before do working
            let mergedOldTweetsInTimeline = _tweetCache.filter {
                return $0.timelineIndex != nil
            }
            
            let updateDatabaseTaskSignpostID = OSSignpostID(log: log)
            var workingRecords: [WorkingRecord] = []
            os_signpost(.begin, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
            for entity in tweets {
                let processEntityTaskSignpostID = OSSignpostID(log: log)
                os_signpost(.begin, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "process entity %{public}s", entity.idStr)
                defer {
                    os_signpost(.end, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "process entity %{public}s", entity.idStr)
                }
                let recordType: WorkingRecord.RecordType = persistType == .homeTimeline ? .timeline : .userTimeline
                let record = WorkingRecord.createOrMergeTweet(into: managedObjectContext, for: requestTwitterUser, requestTwitterUserID: requestTwitterUserID, entity: entity, recordType: recordType, networkDate: response.networkDate, log: log)
                workingRecords.append(record)
            }   // end for…
            os_signpost(.end, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
            
            // home timeline tasks
            if persistType == .homeTimeline {
                // Task 1: update anchor hasMore
                // update maxID anchor hasMore attribute when fetching on home timeline
                // do not use working records due to anchor tweet is removable on the remote
                var anchorTweet: Tweet?
                if let maxID = query.maxID {
                    do {
                        // load anchor tweet from database
                        let request = Tweet.sortedFetchRequest
                        request.predicate = Tweet.predicate(idStr: maxID)
                        request.returnsObjectsAsFaults = false
                        request.fetchLimit = 1
                        anchorTweet = try managedObjectContext.fetch(request).first
                        anchorTweet?.timelineIndex?.update(hasMore: false)
                    } catch {
                        assertionFailure(error.localizedDescription)
                    }
                }
                
                // Task 2: set last tweet hasMore when fetched tweets no overlap with the timeline in the local database
                let _oldestRecord = workingRecords
                    .sorted(by: { $0.tweet.createdAt < $1.tweet.createdAt })
                    .first
                if let oldestRecord = _oldestRecord {
                    if let anchorTweet = anchorTweet {
                        // using anchor. set hasMore when (overlap itself OR no overlap) AND oldest record NOT anchor
                        let isNoOverlap = mergedOldTweetsInTimeline.isEmpty
                        let isOnlyOverlapItself = mergedOldTweetsInTimeline.count == 1 && mergedOldTweetsInTimeline.first?.idStr == anchorTweet.idStr
                        let isAnchorEqualOldestRecord = oldestRecord.tweet.idStr == anchorTweet.idStr
                        if (isNoOverlap || isOnlyOverlapItself) && !isAnchorEqualOldestRecord {
                            oldestRecord.tweet.timelineIndex?.update(hasMore: true)
                        }
                        
                    } else if mergedOldTweetsInTimeline.isEmpty {
                        // no anchor. set hasMore when no overlap
                        oldestRecord.tweet.timelineIndex?.update(hasMore: true)
                    }
                } else {
                    // empty working record. mark anchor hasMore in the task 1
                }
            }
            
            do {
                try managedObjectContext.saveOrRollback()
                os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: database updated", ((#file as NSString).lastPathComponent), #line, #function)
                
                // print working record tree map
                #if DEBUG
                DispatchQueue.global(qos: .utility).async {
                    let logs = workingRecords
                        .map { record in record.log() }
                        .joined(separator: "\n")
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: working status: \n%s", ((#file as NSString).lastPathComponent), #line, #function, logs)
                    let counting = workingRecords
                        .map { record in record.count() }
                        .reduce(into: WorkingRecord.Counting(), { result, next in result = result + next })
                    let newTweetsInTimeLineCount = workingRecords.reduce(0, { result, next in
                        return next.tweetProcessType == .create ? result + 1 : result
                    })
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: tweet: insert %{public}ldT(%{public}ldTRQ), merge %{public}ldT(%{public}ldTRQ)", ((#file as NSString).lastPathComponent), #line, #function, newTweetsInTimeLineCount, counting.tweet.create, mergedOldTweetsInTimeline.count, counting.tweet.merge)
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: twitter user: insert %{public}ld, merge %{public}ld", ((#file as NSString).lastPathComponent), #line, #function, counting.user.create, counting.user.merge)
                }
                #endif
            } catch {
                os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: database update fail. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                assertionFailure(error.localizedDescription)
            }
            os_signpost(.end, log: .api, name: #function, signpostID: contextTaskSignpostID)
        }   // end perform
    }
}

extension APIService {
    
    struct WorkingIDRecord {
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
    
    class WorkingRecord {
        
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
            case userTimeline
            case retweet
            case quote
            
            var flag: String {
                switch self {
                case .timeline:     return "T"
                case .userTimeline: return "U"
                case .retweet:      return "R"
                case .quote:        return "Q"
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
            for requestTwitterUser: TwitterUser?,
            requestTwitterUserID: TwitterUser.UserID,
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
                createOrMergeTweet(into: managedObjectContext, for: requestTwitterUser, requestTwitterUserID: requestTwitterUserID, entity: entity, recordType: .retweet, networkDate: networkDate, log: log)
            }
            let quoteRecord: WorkingRecord? = entity.quotedStatus.flatMap { entity -> WorkingRecord in
                createOrMergeTweet(into: managedObjectContext, for: requestTwitterUser, requestTwitterUserID: requestTwitterUserID, entity: entity, recordType: .quote, networkDate: networkDate, log: log)
            }
            let children = [retweetRecord, quoteRecord].compactMap { $0 }
            
            if let oldTweet = oldTweet {
                // merge old tweet
                defer {
                    APIService.mergeTweet(for: requestTwitterUser, old: oldTweet, entity: entity, networkDate: networkDate)
                }
                
                if recordType == .timeline {
                    // node is timeline
                    if oldTweet.timelineIndex == nil {
                        // exist tweet not in timeline and contained by other local entities' retweet/quote
                        os_signpost(.event, log: log, name: "update database - process entity: createorMergeTweet", signpostID: processEntityTaskSignpostID, "find old retweet %{public}s", entity.idStr)
                        let timelineIndexProperty = TimelineIndex.Property(userID: requestTwitterUserID, platform: .twitter, createdAt: entity.createdAt)
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
                let (twitterUser, isUserCreated) = createOrMergeTwitterUser(into: managedObjectContext, for: requestTwitterUser, entity: entity.user, networkDate: networkDate, log: log)
                let timelineIndex: TimelineIndex? = {
                    guard recordType == .timeline else { return nil }
                    let timelineIndexProperty = TimelineIndex.Property(userID: requestTwitterUserID, platform: .twitter, createdAt: entity.createdAt)
                    let timelineIndex = TimelineIndex.insert(into: managedObjectContext, property: timelineIndexProperty)
                    os_signpost(.event, log: log, name: "update database - process entity: createorMergeTweet", signpostID: processEntityTaskSignpostID, "did insert new timelineIndex %{public}s", timelineIndex.id.uuidString)
                    return timelineIndex
                }()
                
                let tweetProperty = Tweet.Property(entity: entity, networkDate: networkDate)
                let tweet = Tweet.insert(into: managedObjectContext, property: tweetProperty, retweet: retweetRecord?.tweet, quote: quoteRecord?.tweet, twitterUser: twitterUser, timelineIndex: timelineIndex, likeBy: (entity.favorited ?? false) ? requestTwitterUser : nil, retweetBy: (entity.retweeted ?? false) ? requestTwitterUser : nil)
                
                return WorkingRecord(tweet: tweet, children: children, recordType: recordType, tweetProcessType: .create, userProcessType: isUserCreated ? .create : .merge)
            }
        }
        
    }
    
}

