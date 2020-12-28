//
//  APIService+Friendship.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-2.
//  Copyright © 2020 Twidere. All rights reserved.
//


import os.log
import UIKit
import Combine
import TwitterAPI
import CoreData
import CoreDataStack
import CommonOSLog

extension APIService {
    
    
    /// Toggle friendship between twitterUser and activeTwitterUser
    ///
    /// Following / Following pending <-> Unfollow
    ///
    /// - Parameters:
    ///   - twitterUser: target twitterUser
    ///   - activeTwitterAuthenticationBox: activeTwitterUser's auth box
    /// - Returns: publisher for twitterUser final state
    func toggleFriendship(
        for twitterUser: TwitterUser,
        activeTwitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        
        return friendshipUpdateLocal(
            twitterUserObjectID: twitterUser.objectID,
            twitterAuthenticationBox: activeTwitterAuthenticationBox
        )
        .receive(on: DispatchQueue.main)
        .handleEvents { _ in
            notificationFeedbackGenerator.prepare()
            impactFeedbackGenerator.prepare()
        } receiveOutput: { _ in
            impactFeedbackGenerator.impactOccurred()
        } receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                // TODO: handle error
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: local friendship update fail", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                assertionFailure(error.localizedDescription)
            case .finished:
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: local friendship update success", ((#file as NSString).lastPathComponent), #line, #function)
            }
        }
        .map { friendshipQueryType, targetTwitterUserID in
            self.friendshipUpdateRemote(
                friendshipQueryType: friendshipQueryType,
                twitterUserID: targetTwitterUserID,
                twitterAuthenticationBox: activeTwitterAuthenticationBox
            )
        }
        .switchToLatest()
        .receive(on: DispatchQueue.main)
        .handleEvents(receiveCompletion: { completion in
            // TODO: rollback local change
            switch completion {
            case .failure(let error):
                os_log("%{public}s[%{public}ld], %{public}s: [Friendship] remote friendship update fail: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            case .finished:
                notificationFeedbackGenerator.notificationOccurred(.success)
                os_log("%{public}s[%{public}ld], %{public}s: [Friendship] remote friendship update success", ((#file as NSString).lastPathComponent), #line, #function)
            }
        })
        .eraseToAnyPublisher()
    }
}

extension APIService {
    
    func friendship(
        twitterUserObjectID: NSManagedObjectID,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Relationship>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let sourceID = twitterAuthenticationBox.twitterUserID
        
        let managedObjectContext = backgroundManagedObjectContext
        return Future<Twitter.API.Friendships.FriendshipQuery, Error> { promise in
            managedObjectContext.perform {
                let targetTwitterUser = managedObjectContext.object(with: twitterUserObjectID) as! TwitterUser
                let targetTwitterUserID = targetTwitterUser.id
                let query = Twitter.API.Friendships.FriendshipQuery(sourceID: sourceID, targetID: targetTwitterUserID)
                promise(.success(query))
            }
        }
        .tryMap { query -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Relationship>, Error> in
            guard query.sourceID != query.targetID else {
                throw APIError.implicit(.badRequest)
            }
            
            return Twitter.API.Friendships.friendship(session: self.session, authorization: authorization, query: query)
                .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Relationship>, Error> in
                    return managedObjectContext.performChanges {
                        let relationship = response.value
                        
                        let _sourceTwitterUser: TwitterUser? = {
                            let request = TwitterUser.sortedFetchRequest
                            request.predicate = TwitterUser.predicate(idStr: sourceID)
                            request.fetchLimit = 1
                            request.returnsObjectsAsFaults = false
                            do {
                                return try managedObjectContext.fetch(request).first
                            } catch {
                                assertionFailure(error.localizedDescription)
                                return nil
                            }
                        }()
                        
                        guard let sourceTwitterUser = _sourceTwitterUser else {
                            assertionFailure()
                            return
                        }
                        
                        let targetTwitterUser = managedObjectContext.object(with: twitterUserObjectID) as! TwitterUser
                        targetTwitterUser.update(following: relationship.source.following, from: sourceTwitterUser)
                        sourceTwitterUser.update(following: relationship.source.followedBy, from: targetTwitterUser)
                        targetTwitterUser.update(followRequestSent: relationship.source.followingRequested, from: sourceTwitterUser)
                    }
                    .setFailureType(to: Error.self)
                    .tryMap { result -> Twitter.Response.Content<Twitter.Entity.Relationship> in
                        switch result {
                        case .success:                  return response
                        case .failure(let error):       throw error
                        }
                    }
                    .eraseToAnyPublisher()
                }
                .switchToLatest()
                .eraseToAnyPublisher()
        }
        .switchToLatest()
        .eraseToAnyPublisher()
    }
    
    // update database local and return query update type for remote request
    func friendshipUpdateLocal(
        twitterUserObjectID: NSManagedObjectID,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<(Twitter.API.Friendships.UpdateQueryType, TwitterUser.ID), Error> {
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        
        var _targetTwitterUserID: TwitterUser.ID?
        var _queryType: Twitter.API.Friendships.UpdateQueryType?
        let managedObjectContext = backgroundManagedObjectContext
        
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
            
            guard let requestTwitterUser = _requestTwitterUser else {
                assertionFailure()
                return
            }
            
            let twitterUser = managedObjectContext.object(with: twitterUserObjectID) as! TwitterUser
            _targetTwitterUserID = twitterUser.id
            
            let isPending = (twitterUser.followRequestSentFrom ?? Set()).contains(where: { $0.id == requestTwitterUserID })
            let isFollowing = (twitterUser.followingFrom ?? Set()).contains(where: { $0.id == requestTwitterUserID })
            
            if isFollowing || isPending {
                _queryType = .destroy
                twitterUser.update(following: false, from: requestTwitterUser)
                twitterUser.update(followRequestSent: false, from: requestTwitterUser)
            } else {
                _queryType = .create
                if twitterUser.protected {
                    twitterUser.update(following: false, from: requestTwitterUser)
                    twitterUser.update(followRequestSent: true, from: requestTwitterUser)
                } else {
                    twitterUser.update(following: true, from: requestTwitterUser)
                    twitterUser.update(followRequestSent: false, from: requestTwitterUser)
                }
            }
        }
        .tryMap { result in
            switch result {
            case .success:
                guard let targetTwitterUserID = _targetTwitterUserID,
                      let queryType = _queryType else {
                    throw APIError.implicit(.badRequest)
                }
                return (queryType, targetTwitterUserID)
                
            case .failure(let error):
                assertionFailure(error.localizedDescription)
                throw error
            }
        }
        .eraseToAnyPublisher()
    }
    
    func friendshipUpdateRemote(
        friendshipQueryType: Twitter.API.Friendships.UpdateQueryType,
        twitterUserID: TwitterUser.ID,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let query = Twitter.API.Friendships.FriendshipUpdateQuery(
            userID: twitterUserID
        )
        // API not return latest friendship status. not merge result
        return Twitter.API.Friendships.friendships(session: session, authorization: authorization, queryKind: friendshipQueryType, query: query)
            .eraseToAnyPublisher()
    }
    
}

// V2 friendship lookup
extension APIService {
    
    func friendshipList(
        kind: FriendshipListKind,
        userID: Twitter.Entity.V2.User.ID,
        maxResults: Int,
        paginationToken: String?,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.FollowLookup.Content>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        
        let query = Twitter.API.V2.FollowLookup.Query(
            userID: userID,
            maxResults: maxResults,
            paginationToken: paginationToken
        )
        
        let lookup: AnyPublisher<Twitter.Response.Content<Twitter.API.V2.FollowLookup.Content>, Error> = {
            switch kind {
            case .following:    return Twitter.API.V2.FollowLookup.following(session: session, authorization: authorization, query: query)
            case .followers:    return Twitter.API.V2.FollowLookup.followers(session: session, authorization: authorization, query: query)
            }
        }()
        
        return lookup
            .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.FollowLookup.Content>, Error> in
                let log = OSLog.api
                
                APIService.logRateLimit(for: response, log: log)
                
                let dictResponse = response.map { response in
                    return Twitter.Response.V2.DictContent(
                        tweets: response.includes?.tweets ?? [],
                        users: response.data ?? [],
                        media: []
                    )
                }
                return APIService.Persist.persistDictContent(managedObjectContext: self.backgroundManagedObjectContext, response: dictResponse, requestTwitterUserID: requestTwitterUserID, log: log)
                    .map { _ in return response }
                    .replaceError(with: response)
                    .setFailureType(to: Error.self)
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
    
    enum FriendshipListKind {
        case following
        case followers
    }
    
}
