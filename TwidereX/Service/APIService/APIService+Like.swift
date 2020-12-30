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
import CoreData
import CoreDataStack
import CommonOSLog

extension APIService {
    
    // make local state change only
    func like(
        tweetObjectID: NSManagedObjectID,
        twitterUserObjectID: NSManagedObjectID,
        favoriteKind: Twitter.API.Favorites.FavoriteKind
    ) -> AnyPublisher<Tweet.ID, Error> {
        var _targetTweetID: Tweet.ID?
        let managedObjectContext = backgroundManagedObjectContext
        return managedObjectContext.performChanges {
            let tweet = managedObjectContext.object(with: tweetObjectID) as! Tweet
            let twitterUser = managedObjectContext.object(with: twitterUserObjectID) as! TwitterUser
            let targetTweet = tweet.retweet ?? tweet
            let targetTweetID = targetTweet.id
            _targetTweetID = targetTweetID
            
            targetTweet.update(liked: favoriteKind == .create, twitterUser: twitterUser)
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
    
    // send favorite request to remote
    func like(
        tweetID: Twitter.Entity.Tweet.ID,
        favoriteKind: Twitter.API.Favorites.FavoriteKind,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Tweet>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        let query = Twitter.API.Favorites.FavoriteQuery(id: tweetID)
        return Twitter.API.Favorites.favorites(session: session, authorization: authorization, favoriteKind: favoriteKind, query: query)
            .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Tweet>, Error> in
                let log = OSLog.api
                let entity = response.value
                let managedObjectContext = self.backgroundManagedObjectContext
                    
                return managedObjectContext.performChanges {
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
                    
                    APIService.CoreData.mergeTweet(for: requestTwitterUser, old: oldTweet, entity: entity, networkDate: response.networkDate)
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: did update tweet %{public}s like status to: %{public}s. now %ld likes", ((#file as NSString).lastPathComponent), #line, #function, entity.idStr, entity.favorited.flatMap { $0 ? "like" : "unlike" } ?? "<nil>", entity.favoriteCount ?? 0)
                }
                .setFailureType(to: Error.self)
                .tryMap { result -> Twitter.Response.Content<Twitter.Entity.Tweet> in
                    switch result {
                    case .success:
                        return response
                    case .failure(let error):
                        throw error
                    }
                }
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    if let responseError = error as? Twitter.API.Error.ResponseError {
                        switch responseError.twitterAPIError {
                        case .accountIsTemporarilyLocked, .rateLimitExceeded:
                            self.error.send(.explicit(.twitterResponseError(responseError)))
                        default:
                            break
                        }
                    }
                case .finished:
                    break
                }
            })
            .eraseToAnyPublisher()
    }
    
}

extension APIService {
    func likeList(
        count: Int = 200,
        userID: String,
        maxID: String? = nil,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        let query = Twitter.API.Timeline.Query(count: count, userID: userID, maxID: maxID)
        return Twitter.API.Favorites.list(session: session, authorization: authorization, query: query)
            .map { response -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> in
                let log = OSLog.api
                
                return APIService.Persist.persistTimeline(
                    managedObjectContext: self.backgroundManagedObjectContext,
                    query: query,
                    response: response,
                    persistType: .likeList,
                    requestTwitterUserID: requestTwitterUserID,
                    log: log
                )
                .setFailureType(to: Error.self)
                .tryMap { result -> Twitter.Response.Content<[Twitter.Entity.Tweet]> in
                    switch result {
                    case .success:
                        return response
                    case .failure(let error):
                        throw error
                    }
                }
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}
