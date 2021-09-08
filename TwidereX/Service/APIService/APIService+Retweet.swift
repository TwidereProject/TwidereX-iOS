//
//  APIService+Retweet.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-15.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import Combine
import TwitterSDK
import CoreData
import CoreDataStack
import CommonOSLog

extension APIService {

    // make local state change only
    @available(*, deprecated, message: "")
    func retweet(
        tweetObjectID: NSManagedObjectID,
        twitterUserObjectID: NSManagedObjectID,
        retweetKind: Twitter.API.Statuses.RetweetKind,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Tweet.ID, Error> {
        var _targetTweetID: Tweet.ID?
        let managedObjectContext = backgroundManagedObjectContext
        return managedObjectContext.performChanges {
            let tweet = managedObjectContext.object(with: tweetObjectID) as! Tweet
            let twitterUser = managedObjectContext.object(with: twitterUserObjectID) as! TwitterUser
            let targetTweet = tweet.retweet ?? tweet
            let targetTweetID = targetTweet.id
            _targetTweetID = targetTweetID
            
            // should update retweet status for tweet and nest retweet (if has)
            [tweet, tweet.retweet]
                .compactMap { $0 }
                .forEach {
                    $0.update(retweeted: retweetKind == .retweet, twitterUser: twitterUser)
                }
        }
        .tryMap { result in
            switch result {
            case .success:
                guard let targetTweetID = _targetTweetID else {
                    throw APIError.implicit(.badRequest)
                }
                return targetTweetID
                
            case .failure(let error):
                assertionFailure(error.localizedDescription)
                throw error
            }
        }
        .eraseToAnyPublisher()
    }
    
    // send retweet request to remote
    func retweet(
        tweetID: Twitter.Entity.Tweet.ID,
        retweetKind: Twitter.API.Statuses.RetweetKind,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Tweet>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        let query = Twitter.API.Statuses.RetweetQuery(id: tweetID)
        return Twitter.API.Statuses.retweet(session: session, authorization: authorization, retweetKind: retweetKind, query: query)
            .handleEvents(receiveOutput: { [weak self] response in
                guard let self = self else { return }
                
                let log = OSLog.api
                
                if let date = response.date, let rateLimit = response.rateLimit {
                    // just print logging
                    let responseNetworkDate = date
                    let resetTimeInterval = rateLimit.reset.timeIntervalSince(responseNetworkDate)
                    let resetTimeIntervalInMin = resetTimeInterval / 60.0
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: API rate limit: %{public}ld/%{public}ld, reset at %{public}s, left: %.2fm (%.2fs)", ((#file as NSString).lastPathComponent), #line, #function, rateLimit.remaining, rateLimit.limit, rateLimit.reset.debugDescription, resetTimeIntervalInMin, resetTimeInterval)
                }
                
                let entity = response.value
                let managedObjectContext = self.backgroundManagedObjectContext
                managedObjectContext.perform {
                    let _requestTwitterUser: TwitterUser? = {
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
                    
                    guard let requestTwitterUser = _requestTwitterUser else {
                        assertionFailure()
                        return
                    }
                    
                    let (tweet, _, _) = APIService.CoreData.createOrMergeTweet(into: managedObjectContext, for: requestTwitterUser, entity: entity, tweetCache: nil, userCache: nil, networkDate: response.networkDate, log: log)
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: did update tweet %{public}s retweet status to: %{public}s. now %ld retweets", ((#file as NSString).lastPathComponent), #line, #function, entity.idStr, (entity.retweetedStatus ?? entity).retweeted.flatMap { $0 ? "retweeted" : "unretweeted" } ?? "<nil>", (entity.retweetedStatus ?? entity).retweetCount ?? 0)
                    
                    // manually update due to API still return retweeted: true
                    tweet.update(retweeted: retweetKind == .retweet, twitterUser: requestTwitterUser)
                    do {
                        try managedObjectContext.saveOrRollback()
                    } catch {
                        assertionFailure(error.localizedDescription)
                    }
                    // TODO: broadcast notification
                }
            })
            .eraseToAnyPublisher()
    }
    
}
