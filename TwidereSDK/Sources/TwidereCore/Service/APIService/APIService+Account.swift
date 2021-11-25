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
            
            let result = Persistence.TwitterUser.createOrMerge(
                in: managedObjectContext,
                context: Persistence.TwitterUser.PersistContext(
                    entity: entity,
                    me: nil,
                    cache: nil,
                    networkDate: response.networkDate
                )
            )

            let flag = result.isNewInsertion ? "+" : "~"
            os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: twitter user [%s](%s)%s verified", ((#file as NSString).lastPathComponent), #line, #function, flag, result.user.id, result.user.username)
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
            let result = Persistence.MastodonUser.createOrMerge(
                in: managedObjectContext,
                context: context
            )
            let user = result.user
            let isCreated = result.isNewInsertion
            let flag = isCreated ? "+" : "~"
            os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: mastodon user [%s](%s)%s verified", ((#file as NSString).lastPathComponent), #line, #function, flag, user.id, user.username)
        }
        
        return response
    }

}
