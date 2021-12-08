//
//  APIService+Block.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-13.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK
import MastodonSDK

extension APIService {

    public func block(
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async throws {
        switch (user, authenticationContext) {
        case (.twitter(let record), .twitter(let authenticationContext)):
            _ = try await block(
                record: record,
                authenticationContext: authenticationContext
            )
        case (.mastodon(let record), .mastodon(let authenticationContext)):
            _ = try await block(
                record: record,
                authenticationContext: authenticationContext
            )
        default:
            break
        }
    }

}

extension APIService {
    
    private struct TwitterBlockContext {
        let sourceUserID: TwitterUser.ID
        let targetUserID: TwitterUser.ID
        let targetUsername: String
        let isBlocking: Bool
        let isFollowing: Bool
    }
    
    func block(
        record: ManagedObjectRecord<TwitterUser>,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Block.BlockContent> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let blockContext: TwitterBlockContext = try await managedObjectContext.performChanges {
            guard let user = record.object(in: managedObjectContext),
                  let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
            else {
                throw AppError.implicit(.badRequest)
            }
            let me = authentication.user
            let isBlocking = user.blockingBy.contains(me)
            let isFollowing = user.followingBy.contains(me)
            // toggle block state
            user.update(isBlock: !isBlocking, by: me)
            // update follow state implicitly
            if !isBlocking {
                // will do block action. set to unfollow
                user.update(isFollow: false, by: me)
            }
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Local] update user[\(user.id)](\(user.username)) block state: \(!isBlocking)")
            return TwitterBlockContext(
                sourceUserID: me.id,
                targetUserID: user.id,
                targetUsername: user.username,
                isBlocking: isBlocking,
                isFollowing: isFollowing
            )
        }
        
        let result: Result<Twitter.Response.Content<Twitter.API.V2.User.Block.BlockContent>, Error>
        do {
            if blockContext.isBlocking {
                let response = try await Twitter.API.V2.User.Block.unblock(
                    session: session,
                    sourceUserID: blockContext.sourceUserID,
                    targetUserID: blockContext.targetUserID,
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            } else {
                let response = try await Twitter.API.V2.User.Block.block(
                    session: session,
                    sourceUserID: blockContext.sourceUserID,
                    query: Twitter.API.V2.User.Block.BlockQuery(targetUserID: blockContext.targetUserID),
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            }
        } catch {
            result = .failure(error)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] update user[\(blockContext.targetUserID)](\(blockContext.targetUsername)) block failure: \(error.localizedDescription)")
        }
        
        try await managedObjectContext.performChanges {
            guard let user = record.object(in: managedObjectContext),
                  let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
            else { return }
            let me = authentication.user
            
            switch result {
            case .success(let response):
                let isBlocking = response.value.data.blocking
                user.update(isBlock: isBlocking, by: me)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] update user[\(blockContext.targetUserID)](\(blockContext.targetUsername)) block state: \(isBlocking)")
            case .failure:
                // rollback
                user.update(isBlock: blockContext.isBlocking, by: me)
                user.update(isFollow: blockContext.isFollowing, by: me)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] rollback user[\(blockContext.targetUserID)](\(blockContext.targetUsername)) block state")
            }
        }

        let response = try result.get()
        return response
    }
    
}

extension APIService {
    
    private struct MastodonBlockContext {
        let sourceUserID: MastodonUser.ID
        let targetUserID: MastodonUser.ID
        let targetUsername: String
        let isBlocking: Bool
        let isFollowing: Bool
    }
    
    func block(
        record: ManagedObjectRecord<MastodonUser>,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let blockContext: MastodonBlockContext = try await managedObjectContext.performChanges {
            guard let user = record.object(in: managedObjectContext),
                  let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
            else {
                throw AppError.implicit(.badRequest)
            }
            let me = authentication.user
            let isBlocking = user.blockingBy.contains(me)
            let isFollowing = user.followingBy.contains(me)
            // toggle block state
            user.update(isBlock: !isBlocking, by: me)
            // update follow state implicitly
            if !isBlocking {
                // will do block action. set to unfollow
                user.update(isFollow: false, by: me)
            }
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Local] update user[\(user.id)](\(user.username)) block state: \(!isBlocking)")
            return MastodonBlockContext(
                sourceUserID: me.id,
                targetUserID: user.id,
                targetUsername: user.username,
                isBlocking: isBlocking,
                isFollowing: isFollowing
            )
        }
        
        let result: Result<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>
        do {
            if blockContext.isBlocking {
                let response = try await Mastodon.API.Account.unblock(
                    session: session,
                    domain: authenticationContext.domain,
                    accountID: blockContext.targetUserID,
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            } else {
                let response = try await Mastodon.API.Account.block(
                    session: session,
                    domain: authenticationContext.domain,
                    accountID: blockContext.targetUserID,
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            }
        } catch {
            result = .failure(error)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] update user[\(blockContext.targetUserID)](\(blockContext.targetUsername)) block failure: \(error.localizedDescription)")
        }
        
        try await managedObjectContext.performChanges {
            guard let user = record.object(in: managedObjectContext),
                  let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
            else { return }
            let me = authentication.user
            
            switch result {
            case .success(let response):
                let relationship = response.value
                Persistence.MastodonUser.update(
                    mastodonUser: user,
                    context: Persistence.MastodonUser.RelationshipContext(
                        entity: relationship,
                        me: me,
                        networkDate: response.networkDate
                    )
                )
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] update user[\(blockContext.targetUserID)](\(blockContext.targetUsername)) block state: \(relationship.blocking)")
            case .failure:
                // rollback
                user.update(isBlock: blockContext.isBlocking, by: me)
                user.update(isFollow: blockContext.isFollowing, by: me)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] rollback user[\(blockContext.targetUserID)](\(blockContext.targetUsername)) block state")
            }
        }
        
        let response = try result.get()
        return response
    }
    
}
