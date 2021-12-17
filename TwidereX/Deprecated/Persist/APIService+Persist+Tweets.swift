//
//  APIService+Timeline.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-30.
//

import os.log
import func QuartzCore.CACurrentMediaTime
import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import TwitterSDK

extension APIService.Persist {
    
    static func persistTweets(
        managedObjectContext: NSManagedObjectContext,
        query: Twitter.API.Timeline.TimelineQuery?,
        response: Twitter.Response.Content<[Twitter.Entity.Tweet]>,
        persistType: PersistType,
        requestTwitterUserID: TwitterUser.ID, log: OSLog
    ) -> AnyPublisher<Result<Void, Error>, Never> {
        return managedObjectContext.performChanges {
            let tweets = response.value
            os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: persist %{public}ld tweets…", ((#file as NSString).lastPathComponent), #line, #function, tweets.count)
            
            let contextTaskSignpostID = OSSignpostID(log: log)
            let start = CACurrentMediaTime()
            os_signpost(.begin, log: log, name: #function, signpostID: contextTaskSignpostID)
            defer {
                os_signpost(.end, log: .api, name: #function, signpostID: contextTaskSignpostID)
                let end = CACurrentMediaTime()
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: persist cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - start)
            }
            
            // load request twitter user
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
            
            // load working set into context to avoid cache miss
            let cacheTaskSignpostID = OSSignpostID(log: log)
            os_signpost(.begin, log: log, name: "load tweets & users into cache", signpostID: cacheTaskSignpostID)
            
            // contains retweet and quote
            let tweetCache: PersistCache<Tweet> = {
                let cache = PersistCache<Tweet>()
                let cacheIDs = PersistCache<Tweet>.ids(for: tweets)
                let cachedTweets: [Tweet] = {
                    let request = Tweet.sortedFetchRequest
                    let idStrs = Array(cacheIDs)
                    request.predicate = Tweet.predicate(idStrs: idStrs)
                    //request.returnsObjectsAsFaults = false
                    //request.relationshipKeyPathsForPrefetching = [#keyPath(Tweet.retweet), #keyPath(Tweet.quote)]
                    do {
                        return try managedObjectContext.fetch(request)
                    } catch {
                        assertionFailure(error.localizedDescription)
                        return []
                    }
                }()
                for tweet in cachedTweets {
                    cache.dictionary[tweet.id] = tweet
                }
                os_signpost(.event, log: log, name: "load tweets into cache", signpostID: cacheTaskSignpostID, "cached %{public}ld tweets", cachedTweets.count)
                return cache
            }()
            
            let userCache: PersistCache<TwitterUser> = {
                let cache = PersistCache<TwitterUser>()
                let cacheIDs = PersistCache<TwitterUser>.ids(for: tweets)
                let cachedTwitterUsers: [TwitterUser] = {
                    let request = TwitterUser.sortedFetchRequest
                    let idStrs = Array(cacheIDs)
                    request.predicate = TwitterUser.predicate(idStrs: idStrs)
                    //request.returnsObjectsAsFaults = false
                    do {
                        return try managedObjectContext.fetch(request)
                    } catch {
                        assertionFailure(error.localizedDescription)
                        return []
                    }
                }()
                for twitterUser in cachedTwitterUsers {
                    cache.dictionary[twitterUser.id] = twitterUser
                }
                return cache
            }()
            
            os_signpost(.end, log: log, name: "load tweets & users into cache", signpostID: cacheTaskSignpostID)
            
            // remote timeline merge local timeline record set
            // declare it before persist
            let mergedOldTweetsInTimeline = tweetCache.dictionary.values.filter {
                return $0.timelineIndexes?.contains(where: { $0.userID == requestTwitterUserID }) ?? false
            }
            
            let updateDatabaseTaskSignpostID = OSSignpostID(log: log)
            let memoType: PersistMemo<Tweet, TwitterUser>.MemoType = {
                switch persistType {
                case .homeTimeline:     return .homeTimeline
                case .mentionTimeline:  return .mentionTimeline
                case .userTimeline:     return .userTimeline
                case .likeList:         return .likeList
                case .searchList:       return .searchList
                case .lookUp:           return .lookUp
                }
            }()

            var persistMemos: [PersistMemo<Tweet, TwitterUser>] = []
            os_signpost(.begin, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
            for entity in tweets {
                let processEntityTaskSignpostID = OSSignpostID(log: log)
                os_signpost(.begin, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "process entity %{public}s", entity.idStr)
                defer {
                    os_signpost(.end, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "process entity %{public}s", entity.idStr)
                }
                let memo = PersistMemo.createOrMergeTweet(
                    into: managedObjectContext,
                    for: requestTwitterUser,
                    requestTwitterUserID: requestTwitterUserID,
                    entity: entity,
                    memoType: memoType,
                    tweetCache: tweetCache,
                    userCache: userCache,
                    networkDate: response.networkDate,
                    log: log
                )
                persistMemos.append(memo)
            }   // end for…
            os_signpost(.end, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
            
            // home & mention timeline tasks
            switch persistType {
            case .homeTimeline, .mentionTimeline:
                // Task 1: update anchor hasMore
                // update maxID anchor hasMore attribute when fetching on home timeline
                // do not use working records due to anchor tweet is removable on the remote
                var anchorTweet: Tweet?
                if let maxID = query?.maxID {
                    do {
                        // load anchor tweet from database
                        let request = Tweet.sortedFetchRequest
                        request.predicate = Tweet.predicate(idStr: maxID)
                        request.returnsObjectsAsFaults = false
                        request.fetchLimit = 1
                        anchorTweet = try managedObjectContext.fetch(request).first
                        if persistType == .homeTimeline {
                            let timelineIndex = anchorTweet.flatMap { tweet in
                                tweet.timelineIndexes?.first(where: { $0.userID == requestTwitterUserID })
                            }
                            timelineIndex?.update(hasMore: false)
                        } else if persistType == .mentionTimeline {
                            let mentionTimelineIndex = anchorTweet.flatMap { tweet in
                                tweet.mentionTimelineIndexes?.first(where: { $0.userID == requestTwitterUserID })
                            }
                            mentionTimelineIndex?.update(hasMore: false)
                        } else {
                            assertionFailure()
                        }
                    } catch {
                        assertionFailure(error.localizedDescription)
                    }
                }
                
                // Task 2: set last tweet hasMore when fetched tweets not overlap with the timeline in the local database
                let _oldestMemo = persistMemos
                    .sorted(by: { $0.status.createdAt < $1.status.createdAt })
                    .first
                if let oldestMemo = _oldestMemo {
                    if let anchorTweet = anchorTweet {
                        // using anchor. set hasMore when (overlap itself OR no overlap) AND oldest record NOT anchor
                        let isNoOverlap = mergedOldTweetsInTimeline.isEmpty
                        let isOnlyOverlapItself = mergedOldTweetsInTimeline.count == 1 && mergedOldTweetsInTimeline.first?.id == anchorTweet.id
                        let isAnchorEqualOldestRecord = oldestMemo.status.id == anchorTweet.id
                        if (isNoOverlap || isOnlyOverlapItself) && !isAnchorEqualOldestRecord {
                            if persistType == .homeTimeline {
                                let timelineIndex = oldestMemo.status.timelineIndexes?
                                    .first(where: { $0.userID == requestTwitterUserID })
                                timelineIndex?.update(hasMore: true)
                            } else if persistType == .mentionTimeline {
                                let mentionTimelineIndex = oldestMemo.status.mentionTimelineIndexes?
                                    .first(where: { $0.userID == requestTwitterUserID })
                                mentionTimelineIndex?.update(hasMore: true)
                            } else {
                                assertionFailure()
                            }
                        }
                        
                    } else if mergedOldTweetsInTimeline.isEmpty {
                        // no anchor. set hasMore when no overlap
                        if persistType == .homeTimeline {
                            let timelineIndex = oldestMemo.status.timelineIndexes?
                                .first(where: { $0.userID == requestTwitterUserID })
                            timelineIndex?.update(hasMore: true)
                        } else if persistType == .mentionTimeline {
                            let mentionTimelineIndex = oldestMemo.status.mentionTimelineIndexes?
                                .first(where: { $0.userID == requestTwitterUserID })
                            mentionTimelineIndex?.update(hasMore: true)
                        }
                    }
                } else {
                    // empty working record. mark anchor hasMore in the task 1
                }
            default:
                break
            }
            
            // print working record tree map
            #if DEBUG
            DispatchQueue.global(qos: .utility).async {
                let logs = persistMemos
                    .map { record in record.log() }
                    .joined(separator: "\n")
                os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: working status: \n%s", ((#file as NSString).lastPathComponent), #line, #function, logs)
                let counting = persistMemos
                    .map { record in record.count() }
                    .reduce(into: PersistMemo.Counting(), { result, next in result = result + next })
                let newTweetsInTimeLineCount = persistMemos.reduce(0, { result, next in
                    return next.statusProcessType == .create ? result + 1 : result
                })
                os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: tweet: insert %{public}ldT(%{public}ldTRQ), merge %{public}ldT(%{public}ldTRQ)", ((#file as NSString).lastPathComponent), #line, #function, newTweetsInTimeLineCount, counting.status.create, mergedOldTweetsInTimeline.count, counting.status.merge)
                os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: twitter user: insert %{public}ld, merge %{public}ld", ((#file as NSString).lastPathComponent), #line, #function, counting.me.create, counting.me.merge)
            }
            #endif
        }
        .eraseToAnyPublisher()
    }
}
