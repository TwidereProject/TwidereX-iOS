//
//  APIService+Mute.swift
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

    public func mute(
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async throws {
        switch (user, authenticationContext) {
        case (.twitter(let record), .twitter(let authenticationContext)):
            _ = try await mute(
                record: record,
                authenticationContext: authenticationContext
            )
        case (.mastodon(let record), .mastodon(let authenticationContext)):
            _ = try await mute(
                record: record,
                authenticationContext: authenticationContext
            )
        default:
            break
        }
    }
    
}

extension APIService {
    
    private struct TwitterMuteContext {
        let sourceUserID: TwitterUser.ID
        let targetUserID: TwitterUser.ID
        let targetUsername: String
        let isMuting: Bool
    }
    
    func mute(
        record: ManagedObjectRecord<TwitterUser>,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Mute.MuteContent> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let muteContext: TwitterMuteContext = try await managedObjectContext.performChanges {
            guard let user = record.object(in: managedObjectContext),
                  let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
            else {
                throw AppError.implicit(.badRequest)
            }
            let me = authentication.user
            let isMuting = user.mutingBy.contains(me)
            let isFollowing = user.followingBy.contains(me)
            // toggle mute state
            user.update(isMute: !isMuting, by: me)
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Local] update user[\(user.id)](\(user.username)) mute state: \(!isMuting)")
            return TwitterMuteContext(
                sourceUserID: me.id,
                targetUserID: user.id,
                targetUsername: user.username,
                isMuting: isMuting
            )
        }
        
        let result: Result<Twitter.Response.Content<Twitter.API.V2.User.Mute.MuteContent>, Error>
        do {
            if muteContext.isMuting {
                let response = try await Twitter.API.V2.User.Mute.unmute(
                    session: session,
                    sourceUserID: muteContext.sourceUserID,
                    targetUserID: muteContext.targetUserID,
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            } else {
                let response = try await Twitter.API.V2.User.Mute.mute(
                    session: session,
                    sourceUserID: muteContext.sourceUserID,
                    query: Twitter.API.V2.User.Mute.MuteQuery(targetUserID: muteContext.targetUserID),
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            }
        } catch {
            result = .failure(error)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] update user[\(muteContext.targetUserID)](\(muteContext.targetUsername)) mute failure: \(error.localizedDescription)")
        }
        
        try await managedObjectContext.performChanges {
            guard let user = record.object(in: managedObjectContext),
                  let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
            else { return }
            let me = authentication.user
            
            switch result {
            case .success(let response):
                let isMuting = response.value.data.muting
                user.update(isMute: isMuting, by: me)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] update user[\(muteContext.targetUserID)](\(muteContext.targetUsername)) mute state: \(isMuting)")
            case .failure:
                // rollback
                user.update(isMute: muteContext.isMuting, by: me)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] rollback user[\(muteContext.targetUserID)](\(muteContext.targetUsername)) mute state")
            }
        }

        let response = try result.get()
        return response
    }
    
}

extension APIService {
    
    private struct MastodonMuteContext {
        let sourceUserID: MastodonUser.ID
        let targetUserID: MastodonUser.ID
        let targetUsername: String
        let isMuting: Bool
    }
    
    func mute(
        record: ManagedObjectRecord<MastodonUser>,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let muteContext: MastodonMuteContext = try await managedObjectContext.performChanges {
            guard let user = record.object(in: managedObjectContext),
                  let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
            else {
                throw AppError.implicit(.badRequest)
            }
            let me = authentication.user
            let isMuting = user.mutingBy.contains(me)
            // toggle mute state
            user.update(isMute: !isMuting, by: me)
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Local] update user[\(user.id)](\(user.username)) mute state: \(!isMuting)")
            return MastodonMuteContext(
                sourceUserID: me.id,
                targetUserID: user.id,
                targetUsername: user.username,
                isMuting: isMuting
            )
        }
        
        let result: Result<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>
        do {
            if muteContext.isMuting {
                let response = try await Mastodon.API.Account.unmute(
                    session: session,
                    domain: authenticationContext.domain,
                    accountID: muteContext.targetUserID,
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            } else {
                let response = try await Mastodon.API.Account.mute(
                    session: session,
                    domain: authenticationContext.domain,
                    accountID: muteContext.targetUserID,
                    authorization: authenticationContext.authorization
                )
                result = .success(response)
            }
        } catch {
            result = .failure(error)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] update user[\(muteContext.targetUserID)](\(muteContext.targetUsername)) mute failure: \(error.localizedDescription)")
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
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] update user[\(muteContext.targetUserID)](\(muteContext.targetUsername)) mute state: \(relationship.muting.debugDescription)")
            case .failure:
                // rollback
                user.update(isMute: muteContext.isMuting, by: me)
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Remote] rollback user[\(muteContext.targetUserID)](\(muteContext.targetUsername)) mute state")
            }
        }
        
        let response = try result.get()
        return response
    }
    
}
