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
    
    /// Toggle friendship between user and *me*
    ///
    /// Following / Following pending <-> Unfollow
    /// - Parameters:
    ///   - user: target user record
    ///   - authenticationContext: `AuthenticationContext`
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
//            _ = try await like(
//                record: record,
//                authenticationContext: authenticationContext
//            )
        default:
            assertionFailure()
        }
    }
}

extension APIService {
    private struct TwitterFollowContext {
        let sourceUserID: TwitterUser.ID
        let targetUserID: TwitterUser.ID
        let isFollowing: Bool
        let isPending: Bool
        let needsUndoFollow: Bool
    }
    
    func friendship(
        record: ManagedObjectRecord<TwitterUser>,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Follow.FollowContent> {
        let managedObjectContext = backgroundManagedObjectContext
        
        // update friendship state and retrieve friendship context
        let _followContext: TwitterFollowContext? = try await managedObjectContext.performChanges {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext),
                  let user = record.object(in: managedObjectContext)
            else { return nil }
            let me = authentication.twitterUser
            
            let isFollowing = user.followingBy.contains(me)
            let isPending = user.followRequestSentFrom.contains(me)
            let needsUndoFollow = isFollowing || isPending
            
            if needsUndoFollow {
                // undo follow
                user.update(isFollow: false, by: me)
                user.update(isFollowRequestSent: false, from: me)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Local] update user friendship: undo follow")
            } else {
                // follow
                if user.protected {
                    user.update(isFollow: false, by: me)
                    user.update(isFollowRequestSent: true, from: me)
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Local] update user friendship: pending follow")
                } else {
                    user.update(isFollow: true, by: me)
                    user.update(isFollowRequestSent: false, from: me)
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Local] update user friendship: following")
                }
            }
            let context = TwitterFollowContext(
                sourceUserID: me.id,
                targetUserID: user.id,
                isFollowing: isFollowing,
                isPending: isPending,
                needsUndoFollow: needsUndoFollow
            )
            return context
        }
        guard let followContext = _followContext else {
            throw APIService.APIError.implicit(.badRequest)
        }
        
        // request follow or undo follow
        let result: Result<Twitter.Response.Content<Twitter.API.V2.User.Follow.FollowContent>, Error>
        do {
            if followContext.needsUndoFollow  {
                let response = try await Twitter.API.V2.User.Follow.undoFollow(
                    session: session,
                    sourceUserID: followContext.sourceUserID,
                    targetUserID: followContext.targetUserID,
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            } else {
                let response = try await Twitter.API.V2.User.Follow.follow(
                    session: session,
                    sourceUserID: followContext.sourceUserID,
                    targetUserID: followContext.targetUserID,
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            }
        } catch {
            result = .failure(error)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] update friendship failure: \(error.localizedDescription)")
        }
        
        // update friendship state
        try await managedObjectContext.performChanges {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext),
                  let user = record.object(in: managedObjectContext)
            else { return }
            
            let me = authentication.twitterUser
            
            switch result {
            case .success(let response):
                let following = response.value.data.following
                user.update(isFollow: following, by: me)
                if let pendingFollow = response.value.data.pendingFollow {
                    user.update(isFollowRequestSent: pendingFollow, from: me)
                } else {
                    user.update(isFollowRequestSent: false, from: me)
                }
                if !followContext.needsUndoFollow {
                    // break blocking implicitly
                    user.update(isBlock: false, by: me)
                }
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] update user friendship: following \(following)")
            case .failure:
                // rollback
                user.update(isFollow: followContext.isFollowing, by: me)
                user.update(isFollowRequestSent: followContext.isPending, from: me)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] rollback user friendship")
            }
        }
        
        let response = try result.get()
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
    @available(*, deprecated, message: "")
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
//                        targetTwitterUser.update(following: relationship.source.following, by: sourceTwitterUser)
//                        sourceTwitterUser.update(following: relationship.source.followedBy, by: targetTwitterUser)
//                        targetTwitterUser.update(followRequestSent: relationship.source.followingRequested, from: sourceTwitterUser)
//                        targetTwitterUser.update(muting: relationship.source.muting, by: sourceTwitterUser)
//                        targetTwitterUser.update(blocking: relationship.source.blocking, by: sourceTwitterUser)
//                        sourceTwitterUser.update(blocking: relationship.source.blockedBy, by: targetTwitterUser)
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
