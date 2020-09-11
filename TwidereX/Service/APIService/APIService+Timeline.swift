//
//  APIService+Timeline.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
import Combine
import TwitterAPI
import CoreDataStack
import CommonOSLog
import DateToolsSwift

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
                    
                    // 1. fetch local exist tweets, retweets, twitter user
                    let retrieveStorageEnityTaskSignpostID = OSSignpostID(log: log)
                    os_signpost(.begin, log: log, name: "retrieve exist entity", signpostID: retrieveStorageEnityTaskSignpostID)
                    // 1.1 fetch timeline tweets
                    let existTimelineTweets: [Tweet] = {
                        let incoming = tweets.map { $0.idStr } + tweets.compactMap { $0.retweetedStatus?.idStr }
                        let request = Tweet.sortedFetchRequest
                        request.returnsObjectsAsFaults = false
                        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                            Tweet.predicate(idStrs: incoming),
                            Tweet.inTimeline(),
                        ])
                        do {
                            return try self.backgroundManagedObjectContext.fetch(request)
                        } catch {
                            assertionFailure(error.localizedDescription)
                            return []
                        }
                    }()
                    os_signpost(.event, log: log, name: "retrieve exist entity - tweets", signpostID: retrieveStorageEnityTaskSignpostID, "find %{public}ld exist tweets", existTimelineTweets.count)
                    // 1.2 fetch not timeline retweets
                    let existNotInTimelineRetweets: [Tweet] = {
                        let incoming = tweets.map { $0.idStr } + tweets.compactMap { $0.retweetedStatus?.idStr }
                        let request = Tweet.sortedFetchRequest
                        request.returnsObjectsAsFaults = false
                        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                            Tweet.predicate(idStrs: incoming),
                            Tweet.notInTimeline(),
                        ])
                        do {
                            return try self.backgroundManagedObjectContext.fetch(request)
                        } catch {
                            assertionFailure(error.localizedDescription)
                            return []
                        }
                    }()
                    os_signpost(.event, log: log, name: "retrieve exist entity - retweets", signpostID: retrieveStorageEnityTaskSignpostID, "find %{public}ld exist retweets", existNotInTimelineRetweets.count)
                    // 1.3 fetch twitter users
                    let existUsers: [TwitterUser] = {
                        let request = TwitterUser.sortedFetchRequest
                        request.returnsObjectsAsFaults = false
                        let idStrs = Array(Set(tweets.map { $0.user.idStr }))
                        request.predicate = TwitterUser.predicate(idStrs: idStrs)
                        do {
                            return try self.backgroundManagedObjectContext.fetch(request)
                        } catch {
                            assertionFailure(error.localizedDescription)
                            return []
                        }
                    }()
                    os_signpost(.event, log: log, name: "retrieve exist entity - twitter users", signpostID: retrieveStorageEnityTaskSignpostID, "find %{public}ld exist twitter user", existUsers.count)
                    os_signpost(.end, log: log, name: "retrieve exist entity", signpostID: retrieveStorageEnityTaskSignpostID)
                    
                    let updateDatabaseTaskSignpostID = OSSignpostID(log: log)
                    os_signpost(.begin, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
                    var newUsers: [TwitterUser] = []
                    var newTweets: [Tweet] = []
                    var newRetweets: [Tweet] = []
                    var oldTweets: [Tweet] = []
                    
                    for entity in tweets {
                        let processEntityTaskSignpostID = OSSignpostID(log: log)
                        os_signpost(.begin, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "process tweet %{public}s", entity.idStr)

                        // 2. process incoming tweet entity
                        if let oldTweet = existTimelineTweets.first(where: { $0.idStr == entity.idStr }) {
                            oldTweets.append(oldTweet)

                            // 2.1 entity already in timeline (case A3)
                            os_signpost(.event, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "find old tweet %{public}s", entity.idStr)
                            if response.networkDate > oldTweet.updatedAt {
                                // merge old tweet
                                APIService.mergeTweet(old: oldTweet, entity: entity)
                                oldTweet.didUpdate(at: response.networkDate)
                            }
                            if response.networkDate > oldTweet.user.updatedAt {
                                // merge old user
                                APIService.mergeTwitterUser(old: oldTweet.user, entity: entity)
                                oldTweet.user.didUpdate(at: response.networkDate)
                            }
                            if let oldRetweet = oldTweet.retweet, response.networkDate > oldRetweet.updatedAt {
                                // merge old retweet
                                APIService.mergeRetweet(old: oldRetweet, entity: entity)
                                oldRetweet.didUpdate(at: response.networkDate)
                            }
                        } else if let oldRetweet = existNotInTimelineRetweets.first(where: { $0.idStr == entity.idStr }) {
                            // 2.2 entity not in timeline but contained by other local entity's retweet. Make it indexed (case A2)
                            // note: user saw that as retweet and then see it as tweet
                            os_signpost(.event, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "find old retweet %{public}s", entity.idStr)
                            let timelineIndexProperty = TimelineIndex.Property(userID: entity.user.idStr, platform: .twitter, createdAt: entity.createdAt)
                            let timelineIndex = TimelineIndex.insert(into: self.backgroundManagedObjectContext, property: timelineIndexProperty)
                            oldRetweet.update(timelineIndex: timelineIndex)
                            APIService.mergeTweet(old: oldRetweet, entity: entity)
                            oldRetweet.didUpdate(at: response.networkDate)
                            
                            // likes new inserted timeline tweet
                            newTweets.append(oldRetweet)
                        } else {
                            // 2.3 create new timeline index
                            os_signpost(.event, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "create new tweet %{public}s", entity.idStr)
                            let tweetProperty = Tweet.Property(entity: entity, networkDate: response.networkDate)
                            
                            let timelineIndexProperty = TimelineIndex.Property(userID: entity.user.idStr, platform: .twitter, createdAt: entity.createdAt)
                            let timelineIndex = TimelineIndex.insert(into: self.backgroundManagedObjectContext, property: timelineIndexProperty)
                            os_signpost(.event, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "did insert new timelineIndex %{public}s", timelineIndex.id.uuidString)
                            
                            // 2.4 create or reuse new twitter user (just created in the loop)
                            func createOrFetchTwtterUser(twitter entity: Twitter.Entity.Tweet) -> TwitterUser {
                                if let oldUser = existUsers.first(where: { $0.idStr == entity.user.idStr }) {
                                    if response.networkDate > oldUser.updatedAt {
                                        // merge old user
                                        APIService.mergeTwitterUser(old: oldUser, entity: entity)
                                        oldUser.didUpdate(at: response.networkDate)
                                    }
                                    return oldUser
                                } else if let newUser = newUsers.first(where: { $0.idStr == entity.user.idStr }) {
                                    return newUser
                                } else {
                                    let twitterUserProperty = TwitterUser.Property(entity: entity.user, networkDate: response.networkDate)
                                    let twitterUser = TwitterUser.insert(into: self.backgroundManagedObjectContext, property: twitterUserProperty)
                                    os_signpost(.event, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "did insert new twitter user %{public}s: name %s", twitterUser.id.uuidString, twitterUserProperty.name ?? "<nil>")
                                    
                                    newUsers.append(twitterUser)
                                    return twitterUser
                                }
                            }
                            let twitterUser = createOrFetchTwtterUser(twitter: entity)
                            
                            // 2.5 create or reuse retweet (case A1)
                            var retweet: Tweet?
                            if let retweetedStatus = entity.retweetedStatus {
                                if let oldTweet = existTimelineTweets.first(where: { $0.idStr == retweetedStatus.idStr }) {
                                    // retweet in local timeline
                                    retweet = oldTweet
                                } else if let oldRetweet = existNotInTimelineRetweets.first(where: { $0.idStr == retweetedStatus.idStr }) {
                                    // retweet is other tweets' retweet
                                    retweet = oldRetweet
                                } else if let newTweet = newTweets.first(where: { $0.idStr == retweetedStatus.idStr }) {
                                    // retweet is new inserted retweet
                                    retweet = newTweet
                                } else {
                                    // retweet not in local
                                    let retweetProperty = Tweet.Property(entity: retweetedStatus, networkDate: response.networkDate)
                                    let twitterUser = createOrFetchTwtterUser(twitter: retweetedStatus)
                                    retweet = Tweet.insert(into: self.backgroundManagedObjectContext, property: retweetProperty, retweet: nil, twitterUser: twitterUser, timelineIndex: nil)
                                }
                            } else {
                                retweet = nil
                            }
                            
                            // 2.5 create new tweet
                            let tweet = Tweet.insert(
                                into: self.backgroundManagedObjectContext,
                                property: tweetProperty,
                                retweet: retweet,
                                twitterUser: twitterUser,
                                timelineIndex: timelineIndex
                            )
                            newTweets.append(tweet)
                            if let retweet = retweet {
                                newRetweets.append(retweet)
                            }
                            os_signpost(.event, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "did insert new tweet %{public}s", tweet.id.uuidString)
                            os_log(.debug, log: log, "%{public}s[%{public}ld], %{public}s: insert tweet %{public}s: %{public}s - %{public}s…", ((#file as NSString).lastPathComponent), #line, #function, tweet.id.uuidString, tweet.idStr, tweet.text.prefix(15).trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                        
                        // 3.
        
                        os_signpost(.end, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "finish process tweet %{public}s", entity.idStr)
                    }   // end for…
                    os_signpost(.end, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
                    
                    if oldTweets.isEmpty {
                        // may have gap, set oldest tweet has more
                        newTweets.sort(by: { $0.createdAt < $1.createdAt })
                        newTweets.first.flatMap { $0.update(hasMore: true) }
                    }
                    
                    do {
                        try self.backgroundManagedObjectContext.saveOrRollback()
                        os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: database updated", ((#file as NSString).lastPathComponent), #line, #function)
                        os_log(.debug, log: log, "%{public}s[%{public}ld], %{public}s: insert %{public}ld tweets, %{public}ld retweets, %{public}ld twitter users", ((#file as NSString).lastPathComponent), #line, #function, newTweets.count, newRetweets.count, newUsers.count)
                        os_log(.debug, log: log, "%{public}s[%{public}ld], %{public}s: merge %{public}ld tweets, %{public}ld twitter users", ((#file as NSString).lastPathComponent), #line, #function, existTimelineTweets.count, existUsers.count)
                    } catch {
                        os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: database update fail. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    }
                    os_signpost(.end, log: .api, name: #function, signpostID: contextTaskSignpostID)
                }   // end perform
            })
            .eraseToAnyPublisher()
    }
    
    private static func mergeTweet(old tweet: Tweet, entity: Twitter.Entity.Tweet) {
        // only fulfill API supported fields
        tweet.update(text: entity.text)
        tweet.update(retweetCount: entity.retweetCount)
        entity.retweeted.flatMap { tweet.update(retweeted: $0) }
        tweet.update(favoriteCount: entity.favoriteCount)
        entity.favorited.flatMap { tweet.update(favorited: $0) }
        // TODO: merge more fileds
    }
    
    private static func mergeRetweet(old retweet: Tweet, entity: Twitter.Entity.Tweet) {
        // only fulfill API supported fields
        entity.retweetedStatus.flatMap { retweet.update(text: $0.text) }
        retweet.update(retweetCount: entity.retweetCount)
        entity.retweeted.flatMap { retweet.update(retweeted: $0) }
        retweet.update(favoriteCount: entity.favoriteCount)
        entity.favorited.flatMap { retweet.update(favorited: $0) }
        // TODO: merge more fileds
    }
    
    private static func mergeTwitterUser(old user: TwitterUser, entity: Twitter.Entity.Tweet) {
        // only fulfill API supported fields
        entity.user.name.flatMap { user.update(name: $0) }
        entity.user.screenName.flatMap { user.update(screenName: $0) }
        entity.user.profileImageURLHTTPS.flatMap { user.update(profileImageURLHTTPS: $0) }
        // TODO: merge more fileds
    }
}
