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
import TwitterSDK
import CoreData
import CoreDataStack
import CommonOSLog

extension APIService {
    func friendship(
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async throws {
        switch (user, authenticationContext) {
        case (.twitter(let record), .twitter(let authenticationContext)):
            _ = try await friendship(
                record: record,
                authenticationContext: authenticationContext
            )
        case (.mastodon(let record), .mastodon(let authenticationContext)):
            break
        default:
            assertionFailure()
            break
        }
    }
    
}

extension APIService {
    func friendship(
        record: ManagedObjectRecord<TwitterUser>,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.Entity.Relationship> {
        let managedObjectContext = backgroundManagedObjectContext

        let _query: Twitter.API.Friendships.FriendshipQuery? = await {
            await managedObjectContext.perform {
                guard let user = record.object(in: managedObjectContext) else { return nil }
                return Twitter.API.Friendships.FriendshipQuery(
                    sourceID: authenticationContext.userID,
                    targetID: user.id
                )
            }
        }()
        guard let query = _query else {
            assertionFailure()
            throw APIService.APIError.implicit(.badRequest)
        }
        guard query.sourceID != query.targetID else {
            throw APIService.APIError.implicit(.badRequest)
        }
        let response = try await Twitter.API.Friendships.friendship(
            session: session,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        try await managedObjectContext.performChanges {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext),
                  let user = record.object(in: managedObjectContext)
            else { return }
            let me = authentication.twitterUser
            
            let relationship = response.value
            user.update(isFollow: relationship.source.following, by: me)
            me.update(isFollow: relationship.source.followedBy, by: user)       // *not* the same (or reverse) to previous one
            user.update(isFollowRequestSent: relationship.source.followingRequested ?? false, from: me)
            user.update(isMute: relationship.source.muting ?? false, by: me)
            user.update(isBlock: relationship.source.blocking ?? false, by: me)
            me.update(isBlock: relationship.source.blockedBy ?? false, by: user)        // *not* the same (or reverse) to previous one
        }   // end try await managedObjectContext.performChanges
            
        return response
    }
}

extension APIService {
    
    /// Toggle friendship between twitterUser and activeTwitterUser
    ///
    /// Following / Following pending <-> Unfollow
    ///
    /// - Parameters:
    ///   - twitterUser: target twitterUser
    ///   - activeTwitterAuthenticationBox: activeTwitterUser's auth box
    /// - Returns: publisher for twitterUser final state
    @available(*, deprecated, message: "")
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
        .handleEvents(receiveCompletion: { [weak self] completion in
            guard let self = self else { return }
            switch completion {
            case .failure(let error):
                os_log("%{public}s[%{public}ld], %{public}s: [Friendship] remote friendship update fail: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                
                if let responseError = error as? Twitter.API.Error.ResponseError,
                   let twitterAPIError = responseError.twitterAPIError {
                    switch twitterAPIError {
                    case .accountIsTemporarilyLocked, .rateLimitExceeded, .blockedFromRequestFollowingThisUser:
                        self.error.send(.explicit(.twitterResponseError(responseError)))
                    default:
                        break
                    }
                }
                
                // rollback
                self.friendshipUpdateLocal(
                    twitterUserObjectID: twitterUser.objectID,
                    twitterAuthenticationBox: activeTwitterAuthenticationBox
                )
                .sink { completion in
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Friendship] rollback finish", ((#file as NSString).lastPathComponent), #line, #function)
                } receiveValue: { _ in
                    // do nothing
                    notificationFeedbackGenerator.prepare()
                    notificationFeedbackGenerator.notificationOccurred(.error)
                }
                .store(in: &self.disposeBag)

            case .finished:
                notificationFeedbackGenerator.notificationOccurred(.success)
                os_log("%{public}s[%{public}ld], %{public}s: [Friendship] remote friendship update success", ((#file as NSString).lastPathComponent), #line, #function)
            }
        })
        .eraseToAnyPublisher()
    }
    
}

extension APIService {
    
    // update database local and return query update type for remote request
    @available(*, deprecated, message: "")
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
            let isFollowing = (twitterUser.followingBy ?? Set()).contains(where: { $0.id == requestTwitterUserID })
            
            if isFollowing || isPending {
                _queryType = .destroy
//                twitterUser.update(following: false, by: requestTwitterUser)
//                twitterUser.update(followRequestSent: false, from: requestTwitterUser)
            } else {
                _queryType = .create
                if twitterUser.protected {
//                    twitterUser.update(following: false, by: requestTwitterUser)
//                    twitterUser.update(followRequestSent: true, from: requestTwitterUser)
                } else {
//                    twitterUser.update(following: true, by: requestTwitterUser)
//                    twitterUser.update(followRequestSent: false, from: requestTwitterUser)
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
    
    @available(*, deprecated, message: "")
    func friendshipUpdateRemote(
        friendshipQueryType: Twitter.API.Friendships.UpdateQueryType,
        twitterUserID: TwitterUser.ID,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let query = Twitter.API.Friendships.FriendshipUpdateQuery(
            userID: twitterUserID
        )
        // API not return latest friendship status. not merge result
        return Twitter.API.Friendships.friendships(session: session, authorization: authorization, queryKind: friendshipQueryType, query: query)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    if let responseError = error as? Twitter.API.Error.ResponseError {
                        switch responseError.twitterAPIError {
                        case .accountIsTemporarilyLocked, .rateLimitExceeded, .blockedFromRequestFollowingThisUser:
                            self.error.send(.explicit(.twitterResponseError(responseError)))
                        default:
                            break
                        }
                    }
                case .finished:
                    switch friendshipQueryType {
                    case .create:
                        // destroy blocking friendship
                        let managedObjectContext = self.backgroundManagedObjectContext
                        managedObjectContext.performChanges {
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
                            
                            let _twitterUser: TwitterUser? = {
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
                            
                            guard let twitterUser = _twitterUser else {
                                assertionFailure()
                                return
                            }
//                            twitterUser.update(blocking: false, by: requestTwitterUser)
                        }
                        .sink { _ in
                            // do nothing
                        }
                        .store(in: &self.disposeBag)
                    case .destroy, .update:
                        break
                    }
                }
            })
            .eraseToAnyPublisher()
    }
    
}

// V2 friendship lookup
extension APIService {
    
    @available(*, deprecated, message: "")
    func friendshipList(
        kind: FriendshipListKind,
        userID: Twitter.Entity.V2.User.ID,
        maxResults: Int,
        paginationToken: String?,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.FollowLookup.Content>, Error> {
        fatalError()
//        let authorization = twitterAuthenticationBox.twitterAuthorization
//        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
//
//        let query = Twitter.API.V2.FollowLookup.Query(
//            userID: userID,
//            maxResults: maxResults,
//            paginationToken: paginationToken
//        )
//
//        let lookup: AnyPublisher<Twitter.Response.Content<Twitter.API.V2.FollowLookup.Content>, Error> = {
//            switch kind {
//            case .following:    return Twitter.API.V2.FollowLookup.following(session: session, authorization: authorization, query: query)
//            case .followers:    return Twitter.API.V2.FollowLookup.followers(session: session, authorization: authorization, query: query)
//            }
//        }()
//
//        return lookup
//            .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.FollowLookup.Content>, Error> in
//                let log = OSLog.api
//
//                APIService.logRateLimit(for: response, log: log)
//
//                let dictResponse = response.map { response in
//                    return Twitter.Response.V2.DictContent(
//                        tweets: response.includes?.tweets ?? [],
//                        users: response.data ?? [],
//                        media: [],
//                        places: []
//                    )
//                }
//                return APIService.Persist.persistDictContent(managedObjectContext: self.backgroundManagedObjectContext, response: dictResponse, requestTwitterUserID: requestTwitterUserID, log: log)
//                    .map { _ in return response }
//                    .replaceError(with: response)
//                    .setFailureType(to: Error.self)
//                    .eraseToAnyPublisher()
//            }
//            .switchToLatest()
//            .handleEvents(receiveCompletion: { [weak self] completion in
//                guard let self = self else { return }
//                switch completion {
//                case .failure(let error):
//                    if let responseError = error as? Twitter.API.Error.ResponseError {
//                        switch responseError.twitterAPIError {
//                        case .accountIsTemporarilyLocked, .rateLimitExceeded:
//                            self.error.send(.explicit(.twitterResponseError(responseError)))
//                        default:
//                            break
//                        }
//                    }
//                case .finished:
//                    break
//                }
//            })
//            .eraseToAnyPublisher()
    }
    
    enum FriendshipListKind {
        case following
        case followers
    }
    
}
