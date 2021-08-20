//
//  APIService+Account.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-28.
//

import Foundation
import Combine
import CoreDataStack
import CommonOSLog
import TwitterSDK
import MastodonSDK

extension APIService {
    
    public func verifyTwitterCredentials(
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.Entity.User> {
        let response = try await Twitter.API.Account.verifyCredentials(session: session, authorization: authorization)
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let log = OSLog.api
            let entity = response.value
            
            let (twitterUser, isCreated) = Persistence.TwitterUser.createOrMerge(
                in: managedObjectContext,
                context: Persistence.TwitterUser.PersistContext(
                    entity: entity,
                    cache: nil,
                    networkDate: response.networkDate
                )
            )

            let flag = isCreated ? "+" : "~"
            os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: twitter user [%s](%s)%s verified", ((#file as NSString).lastPathComponent), #line, #function, flag, twitterUser.id, twitterUser.username)
        }
        
        return response
    }
    
}

extension APIService {
    public func verifyMastodonCredentials(
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Account> {
        let response = try await Mastodon.API.Account.verifyCredentials(
            session: session,
            domain: domain,
            authorization: authorization
        )
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let log = OSLog.api
            let entity = response.value
            
            let context = Persistence.MastodonUser.PersistContext(
                domain: domain,
                entity: entity,
                cache: nil,
                networkDate: response.networkDate
            )
            let (mastodonUser, isCreated) = Persistence.MastodonUser.createOrMerge(
                in: managedObjectContext,
                context: context
            )
            let flag = isCreated ? "+" : "~"
            os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: mastodon user [%s](%s)%s verified", ((#file as NSString).lastPathComponent), #line, #function, flag, mastodonUser.id, mastodonUser.username)
        }
        
        return response
    }

}
