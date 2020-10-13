//
//  APIService+Like.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-13.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import Combine
import TwitterAPI
import CoreDataStack
import CommonOSLog

extension APIService {
    
    func like(tweetID: Twitter.Entity.Tweet.ID, authorization: Twitter.API.OAuth.Authorization, twitterUserID: TwitterUser.UserID, favoriteKind: Twitter.API.Favorites.FavoriteKind) -> AnyPublisher<Twitter.Response<Twitter.Entity.Tweet>, Error> {
        let query = Twitter.API.Favorites.Query(id: tweetID)
        return Twitter.API.Favorites.favorites(session: session, authorization: authorization, favoriteKind: favoriteKind, query: query)
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
                        request.predicate = TwitterUser.predicate(idStr: twitterUserID)
                        request.fetchLimit = 1
                        request.returnsObjectsAsFaults = false
                        do {
                            return try managedObjectContext.fetch(request).first
                        } catch {
                            assertionFailure(error.localizedDescription)
                            return nil
                        }
                    }()
                    let _oldTweet: Tweet? = {
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
                    
                    guard let requestTwitterUser = _requestTwitterUser,
                          let oldTweet = _oldTweet else {
                        assertionFailure()
                        return
                    }
                    
                    APIService.mergeTweet(for: requestTwitterUser, old: oldTweet, entity: entity, networkDate: response.networkDate)
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: did update tweet %{public}s like status to: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, entity.idStr, entity.favorited.flatMap { $0 ? "like" : "unlike" } ?? "<nil>")
                    
                    // TODO: broadcast notification
                }
            })
            .eraseToAnyPublisher()
    }
    
}
