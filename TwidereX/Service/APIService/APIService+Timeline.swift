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

extension APIService {
    func twitterHomeTimeline(twitterAuthentication authentication: TwitterAuthentication) -> AnyPublisher<Twitter.Response<[Twitter.Entity.Tweet]>, Error> {
        let authorization = Twitter.API.OAuth.Authorization(
            consumerKey: authentication.consumerKey,
            consumerSecret: authentication.consumerSecret,
            accessToken: authentication.accessToken,
            accessTokenSecret: authentication.accessTokenSecret
        )
        
        os_log("%{public}s[%{public}ld], %{public}s: fetch home timeline…", ((#file as NSString).lastPathComponent), #line, #function)

        return Twitter.API.Timeline.homeTimeline(session: session, authorization: authorization)
            .handleEvents(receiveOutput: {response in
                let log = OSLog.api
                if let responseTime = response.responseTime {
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: response cost %{public}ldms", ((#file as NSString).lastPathComponent), #line, #function, responseTime)
                }
                if let rateLimit = response.rateLimit {
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: API rate limit: %{public}ld/%{public}ld, reset at %{public}s", ((#file as NSString).lastPathComponent), #line, #function, rateLimit.remaining, rateLimit.limit, rateLimit.reset.debugDescription)
                }
                // switch to background context
                self.backgroundManagedObjectContext.perform { [weak self] in
                    guard let self = self else { return }
                    let contextTaskSignpostID = OSSignpostID(log: log)
                    os_signpost(.begin, log: log, name: #function, signpostID: contextTaskSignpostID)
                    
                    let tweets = response.value
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: fetch %{public}ld tweets", ((#file as NSString).lastPathComponent), #line, #function, tweets.count)
                    
                    let retrieveStorageEnityTaskSignpostID = OSSignpostID(log: log)
                    os_signpost(.begin, log: log, name: "retrieve exist entity", signpostID: retrieveStorageEnityTaskSignpostID)
                    let existTweets: [Tweet] = {
                        let request = Tweet.sortedFetchRequest
                        request.returnsObjectsAsFaults = false
                        request.predicate = Tweet.predicate(idStrs: tweets.map { $0.idStr })
                        do {
                            return try self.backgroundManagedObjectContext.fetch(request)
                        } catch {
                            assertionFailure(error.localizedDescription)
                            return []
                        }
                    }()
                    os_signpost(.event, log: log, name: "retrieve exist entity - tweets", signpostID: retrieveStorageEnityTaskSignpostID, "find %{public}ld exist tweets", existTweets.count)
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
                    os_signpost(.event, log: log, name: "retrieve exist entity - users", signpostID: retrieveStorageEnityTaskSignpostID, "find %{public}ld exist twitter user", existUsers.count)
                    os_signpost(.end, log: log, name: "retrieve exist entity", signpostID: retrieveStorageEnityTaskSignpostID)
                    
                    let updateDatabaseTaskSignpostID = OSSignpostID(log: log)
                    os_signpost(.begin, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
                    var newUsers: [TwitterUser] = []
                    var newTweets: [Tweet] = []
                    
                    for entity in tweets {
                        let processEntityTaskSignpostID = OSSignpostID(log: log)
                        os_signpost(.begin, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "process tweet %{public}s", entity.idStr)
                        if let oldTweet = existTweets.first(where: { $0.idStr == entity.idStr }) {
                            os_signpost(.event, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "find old tweet %{public}s", entity.idStr)
                            if response.networkDate > oldTweet.updatedAt {
                                // merge old tweet
                                oldTweet.update(text: entity.text)
                                oldTweet.didUpdate(at: response.networkDate)
                            }
                            if response.networkDate > oldTweet.user.updatedAt {
                                // merge old user
                                APIService.merge(old: oldTweet.user, entity: entity)
                                oldTweet.user.didUpdate(at: response.networkDate)
                            }
                        } else {
                            os_signpost(.event, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "create new tweet %{public}s", entity.idStr)
                            let tweetProperty = Tweet.Property(entity: entity, networkDate: response.networkDate)
                            
                            let timelineIndexProperty = TimelineIndex.Property(userID: entity.user.idStr, platform: .twitter, createdAt: entity.createdAt)
                            let timelineIndex = TimelineIndex.insert(into: self.backgroundManagedObjectContext, property: timelineIndexProperty)
                            os_signpost(.event, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "did insert new timelineIndex %{public}s", timelineIndex.id.uuidString)
                            
                            var twitterUser: TwitterUser
                            if let oldUser = existUsers.first(where: { $0.idStr == entity.user.idStr }) {
                                if response.networkDate > oldUser.updatedAt {
                                    // merge old user
                                    APIService.merge(old: oldUser, entity: entity)
                                    oldUser.didUpdate(at: response.networkDate)
                                }
                                twitterUser = oldUser
                            } else if let newUser = newUsers.first(where: { $0.idStr == entity.user.idStr }) {
                                twitterUser = newUser
                            } else {
                                let twitterUserProperty = TwitterUser.Property(entity: entity.user, networkDate: response.networkDate)
                                twitterUser = TwitterUser.insert(into: self.backgroundManagedObjectContext, property: twitterUserProperty)
                                os_signpost(.event, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "did insert new twitter user %{public}s: name %s", twitterUser.id.uuidString, twitterUserProperty.name ?? "<nil>")
                                
                                newUsers.append(twitterUser)
                            }
                            
                            let tweet = Tweet.insert(
                                into: self.backgroundManagedObjectContext,
                                property: tweetProperty,
                                timelineIndex: timelineIndex,
                                twitterUser: twitterUser
                            )
                            newTweets.append(tweet)
                            os_signpost(.event, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "did insert new tweet %{public}s", tweet.id.uuidString)
                            os_log(.debug, log: log, "%{public}s[%{public}ld], %{public}s: insert tweet %{public}s: %{public}s - %{public}s…", ((#file as NSString).lastPathComponent), #line, #function, tweet.id.uuidString, tweet.idStr, tweet.text.prefix(15).trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                        os_signpost(.end, log: log, name: "update database - process entity", signpostID: processEntityTaskSignpostID, "finish process tweet %{public}s", entity.idStr)
                    }   // end for…
                    os_signpost(.end, log: log, name: "update database", signpostID: updateDatabaseTaskSignpostID)
                    
                    do {
                        try self.backgroundManagedObjectContext.saveOrRollback()
                        os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: database updated", ((#file as NSString).lastPathComponent), #line, #function)
                        os_log(.debug, log: log, "%{public}s[%{public}ld], %{public}s: insert %{public}ld tweets, %{public}ld twitter users", ((#file as NSString).lastPathComponent), #line, #function, newTweets.count, newUsers.count)
                        os_log(.debug, log: log, "%{public}s[%{public}ld], %{public}s: merge %{public}ld tweets, %{public}ld twitter users", ((#file as NSString).lastPathComponent), #line, #function, existTweets.count, existUsers.count)
                    } catch {
                        os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: database update fail. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    }
                    os_signpost(.end, log: .api, name: #function, signpostID: contextTaskSignpostID)
                }   // end perform
            })
            .eraseToAnyPublisher()
    }
    
    private static func merge(old user: TwitterUser, entity: Twitter.Entity.Tweet) {
        // only fulfill API supported fields
        entity.user.name.flatMap { user.update(name: $0) }
        entity.user.screenName.flatMap { user.update(screenName: $0) }
        entity.user.profileImageURLHTTPS.flatMap { user.update(profileImageURLHTTPS: $0) }
        // TODO: merge more fileds
    }
}
