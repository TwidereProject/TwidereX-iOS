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
    func follow(
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
