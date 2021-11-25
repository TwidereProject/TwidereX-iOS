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
import CoreData
import CoreDataStack
import TwitterSDK
import MastodonSDK

extension APIService {
    
    /// Query and update friendship for user
    /// - Parameters:
    ///   - user: target user
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
            _ = try await friendship(
                records: [record],
                authenticationContext: authenticationContext
            )
        default:
            assertionFailure()
            break
        }
    }
}

extension APIService {
    public func friendship(
        record: ManagedObjectRecord<TwitterUser>,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.Entity.Relationship> {
        let managedObjectContext = backgroundManagedObjectContext

        let _query: Twitter.API.Friendships.FriendshipQuery? = await managedObjectContext.perform {
            guard let user = record.object(in: managedObjectContext) else { return nil }
            return Twitter.API.Friendships.FriendshipQuery(
                sourceID: authenticationContext.userID,
                targetID: user.id
            )
        }
        guard let query = _query else {
            assertionFailure()
            throw AppError.implicit(.badRequest)
        }
        guard query.sourceID != query.targetID else {
            throw AppError.implicit(.badRequest)
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
            let me = authentication.user
            
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
    public func friendship(
        records: [ManagedObjectRecord<MastodonUser>],
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Relationship]> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let _query: Mastodon.API.Account.RelationshipQuery? = await managedObjectContext.perform {
            var ids: [MastodonUser.ID] = []
            for record in records {
                guard let user = record.object(in: managedObjectContext) else { continue }
                guard user.id != authenticationContext.userID else { continue }
                ids.append(user.id)
            }
            guard !ids.isEmpty else { return nil }
            return Mastodon.API.Account.RelationshipQuery(ids: ids)
        }
        guard let query = _query else {
            throw AppError.implicit(.badRequest)
        }
        
        let response = try await Mastodon.API.Account.relationships(
            session: session,
            domain: authenticationContext.domain,
            query: query,
            authorization: authenticationContext.authorization
        )

        try await managedObjectContext.performChanges {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext) else { return }
            let me = authentication.user

            let relationships = response.value
            for record in records {
                guard let user = record.object(in: managedObjectContext) else { continue }
                guard let relationship = relationships.first(where: { $0.id == user.id }) else { continue }
                Persistence.MastodonUser.update(
                    mastodonUser: user,
                    context: Persistence.MastodonUser.RelationshipContext(
                        entity: relationship,
                        me: me,
                        networkDate: response.networkDate
                    )
                )   // end Persistence.MastodonUser.update
            }   // end for … in …
        }   // end try await managedObjectContext.performChanges
        
        return response
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
