//
//  APIService+Persist+ResponseContent.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-19.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import TwitterAPI

extension APIService.Persist {
    static func persistDictContent(
        managedObjectContext: NSManagedObjectContext,
        response: Twitter.Response.Content<Twitter.Response.V2.DictContent>,
        requestTwitterUserID: TwitterUser.ID,
        log: OSLog
    ) -> AnyPublisher<Result<Void, Error>, Never> {
        let dictContent = response.value
        os_log("%{public}s[%{public}ld], %{public}s: persist %{public}ld tweets %{public}ld twitter users…", ((#file as NSString).lastPathComponent), #line, #function, dictContent.tweetDict.count, dictContent.userDict.count)

        // switch to background context
        return managedObjectContext.performChanges {
            let contextTaskSignpostID = OSSignpostID(log: log)
            os_signpost(.begin, log: log, name: #function, signpostID: contextTaskSignpostID)
            defer {
                os_signpost(.end, log: .api, name: #function, signpostID: contextTaskSignpostID)
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

            // load old tweets into context to avoid cache miss
            let cacheTaskSignpostID = OSSignpostID(log: log)
            os_signpost(.begin, log: log, name: "load tweets into cache", signpostID: cacheTaskSignpostID)
            // contains retweet and quote
            let _tweetCache: [Tweet] = {
                let request = Tweet.sortedFetchRequest
                let idStrs = Array(dictContent.tweetDict.keys)
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
            os_log("%{public}s[%{public}ld], %{public}s: preload %ld tweets in the cache", ((#file as NSString).lastPathComponent), #line, #function, _tweetCache.count)
            
            for (tweetID, tweet) in dictContent.tweetDict {
                guard let authorID = tweet.authorID,
                      let user = dictContent.userDict[authorID] else { continue }
                let info = APIService.CoreData.V2.TwitterInfo(
                    tweet: tweet,
                    user: user,
                    media: dictContent.media(for: tweet),
                    place: dictContent.place(for: tweet),
                    dictContent: dictContent
                )
                
                // collect sibling infos from dict
                // Note: API may only give ID but not return entity. Do not depend on it to judge pointer exist or not
                var repliedToInfo: APIService.CoreData.V2.TwitterInfo?
                var retweetedInfo: APIService.CoreData.V2.TwitterInfo?
                var quotedInfo: APIService.CoreData.V2.TwitterInfo?
                
                for referencedTweet in tweet.referencedTweets ?? [] {
                    guard let referencedType = referencedTweet.type,
                          let referencedTweetID = referencedTweet.id else { continue }
                    guard let targetReferencedTweet = dictContent.tweetDict[referencedTweetID] else { continue }
                    guard let targetReferencedTweetAuthorID = targetReferencedTweet.authorID,
                          let targetReferencedTweetAuthor = dictContent.userDict[targetReferencedTweetAuthorID] else { continue }
                    let targetInfo = APIService.CoreData.V2.TwitterInfo(
                        tweet: targetReferencedTweet,
                        user: targetReferencedTweetAuthor,
                        media: dictContent.media(for: targetReferencedTweet),
                        place: dictContent.place(for: targetReferencedTweet),
                        dictContent: dictContent
                    )
                    switch referencedType {
                    case .repliedTo: repliedToInfo = targetInfo
                    case .retweeted: retweetedInfo = targetInfo
                    case .quoted: quotedInfo = targetInfo
                    }
                }
                
                let (tweet, isTweetCreated, isTwitterUserCreated) = APIService.CoreData.V2.createOrMergeTweet(
                    into: managedObjectContext,
                    for: requestTwitterUser,
                    info: info,
                    repliedToInfo: repliedToInfo,
                    retweetedInfo: retweetedInfo,
                    quotedInfo: quotedInfo,
                    networkDate: response.networkDate,
                    log: log
                )
            }
            
            for (userID, user) in dictContent.userDict {
                _ = APIService.CoreData.V2.createOrMergeTwitterUser(
                    into: managedObjectContext,
                    for: requestTwitterUser,
                    user: user,
                    networkDate: response.networkDate,
                    log: log
                )
            }
        }
        .eraseToAnyPublisher()
    }
}
