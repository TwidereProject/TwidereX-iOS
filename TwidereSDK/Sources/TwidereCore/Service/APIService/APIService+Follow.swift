//
//  APIService+Follow.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-20.
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
    
    /// Toggle friendship between user and *me*
    ///
    /// Following / Following Pending <-> Unfollow
    /// - Parameters:
    ///   - user: target user record
    ///   - authenticationContext: `AuthenticationContext`
    public func follow(
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async throws {
        switch (user, authenticationContext) {
        case (.twitter(let record), .twitter(let authenticationContext)):
            _ = try await follow(
                record: record,
                authenticationContext: authenticationContext
            )
        case (.mastodon(let record), .mastodon(let authenticationContext)):
            _ = try await follow(
                record: record,
                authenticationContext: authenticationContext
            )
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
        let needsUnfollow: Bool
    }
    
    func follow(
        record: ManagedObjectRecord<TwitterUser>,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Follow.FollowContent> {
        let managedObjectContext = backgroundManagedObjectContext
        
        // update friendship state and retrieve friendship context
        let _followContext: TwitterFollowContext? = try await managedObjectContext.performChanges {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext),
                  let user = record.object(in: managedObjectContext)
            else { return nil }
            let me = authentication.user
            
            let isFollowing = user.followingBy.contains(me)
            let isPending = user.followRequestSentFrom.contains(me)
            let needsUnfollow = isFollowing || isPending
            
            if needsUnfollow {
                // unfollow
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
                needsUnfollow: needsUnfollow
            )
            return context
        }
        guard let followContext = _followContext else {
            throw AppError.implicit(.badRequest)
        }
        
        // request follow or unfollow
        let result: Result<Twitter.Response.Content<Twitter.API.V2.User.Follow.FollowContent>, Error>
        do {
            if followContext.needsUnfollow  {
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
            
            let me = authentication.user
            
            switch result {
            case .success(let response):
                Persistence.TwitterUser.update(
                    twitterUser: user,
                    context: Persistence.TwitterUser.RelationshipContext(
                        entity: response.value,
                        me: me,
                        isUnfollowAction: followContext.needsUnfollow,
                        networkDate: response.networkDate
                    )
                )
                let following = response.value.data.following
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
    
    private struct MastodonFollowContext {
        let sourceUserID: MastodonUser.ID
        let targetUserID: MastodonUser.ID
        let isFollowing: Bool
        let isPending: Bool
        let needsUnfollow: Bool
    }
    
    func follow(
        record: ManagedObjectRecord<MastodonUser>,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let managedObjectContext = backgroundManagedObjectContext
        
        // update friendship state and retrieve friendship context
        let _followContext: MastodonFollowContext? = try await managedObjectContext.performChanges {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext),
                  let user = record.object(in: managedObjectContext)
            else { return nil }
            let me = authentication.user
            
            let isFollowing = user.followingBy.contains(me)
            let isPending = user.followRequestSentFrom.contains(me)
            let needsUnfollow = isFollowing || isPending
            
            if needsUnfollow {
                // unfollow
                user.update(isFollow: false, by: me)
                user.update(isFollowRequestSent: false, from: me)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Local] update user friendship: undo follow")
            } else {
                // follow
                if user.locked {
                    user.update(isFollow: false, by: me)
                    user.update(isFollowRequestSent: true, from: me)
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Local] update user friendship: pending follow")
                } else {
                    user.update(isFollow: true, by: me)
                    user.update(isFollowRequestSent: false, from: me)
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Local] update user friendship: following")
                }
            }
            let context = MastodonFollowContext(
                sourceUserID: me.id,
                targetUserID: user.id,
                isFollowing: isFollowing,
                isPending: isPending,
                needsUnfollow: needsUnfollow
            )
            return context
        }
        guard let followContext = _followContext else {
            throw AppError.implicit(.badRequest)
        }
        
        // request follow or unfollow
        let result: Result<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>
        do {
            if followContext.needsUnfollow  {
                let response = try await Mastodon.API.Account.unfollow(
                    session: session,
                    domain: authenticationContext.domain,
                    accountID: followContext.targetUserID,
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            } else {
                let response = try await Mastodon.API.Account.follow(
                    session: session,
                    domain: authenticationContext.domain,
                    accountID: followContext.targetUserID,
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
            
            let me = authentication.user
            
            switch result {
            case .success(let response):
                Persistence.MastodonUser.update(
                    mastodonUser: user,
                    context: Persistence.MastodonUser.RelationshipContext(
                        entity: response.value,
                        me: me,
                        networkDate: response.networkDate
                    )
                )
                let following = response.value.following
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
