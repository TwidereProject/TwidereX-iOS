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
