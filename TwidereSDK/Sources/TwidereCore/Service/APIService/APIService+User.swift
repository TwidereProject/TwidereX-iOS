//
//  APIService+User.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import TwitterSDK
import MastodonSDK

// V2
extension APIService {

    public func twitterUsers(
        userIDs: [Twitter.Entity.User.ID],
        twitterAuthenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Lookup.Content>  {
        let authorization = twitterAuthenticationContext.authorization
        let response = try await Twitter.API.V2.User.Lookup.users(
            session: session,
            userIDs: userIDs,
            authorization: authorization
        )
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let me = twitterAuthenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            for user in response.value.data ?? [] {
                _ = Persistence.TwitterUser.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.TwitterUser.PersistContextV2(
                        entity: user,
                        me: me,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
            }
        }
        
        return response
    }
    
    public func twitterUsers(
        usernames: [String],
        twitterAuthenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Lookup.Content> {
        let authorization = twitterAuthenticationContext.authorization
        let response = try await Twitter.API.V2.User.Lookup.users(
            session: session,
            usernames: usernames,
            authorization: authorization
        )
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let me = twitterAuthenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            for user in response.value.data ?? [] {
                _ = Persistence.TwitterUser.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.TwitterUser.PersistContextV2(
                        entity: user,
                        me: me,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
            }
        }
        
        return response
    }

}

extension APIService {
    
    public func mastodonUser(
        userID: Mastodon.Entity.Account.ID,
        mastodonAuthenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Account> {
        let domain = mastodonAuthenticationContext.domain
        let authorization = mastodonAuthenticationContext.authorization
        let response = try await Mastodon.API.Account.account(
            session: session,
            domain: domain,
            userID: userID,
            authorization: authorization
        )
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            _ = Persistence.MastodonUser.createOrMerge(
                in: managedObjectContext,
                context: Persistence.MastodonUser.PersistContext(
                    domain: domain,
                    entity: response.value,
                    cache: nil,
                    networkDate: response.networkDate
                )
            )
        }
        
        return response
    }
    
}
