//
//  APIService+Notification.swift
//  
//
//  Created by MainasuK on 2022-7-7.
//

import os.log
import Foundation
import MastodonSDK
import TwidereCommon

extension APIService {
 
    public func createMastodonNotificationSubscription(
        query: Mastodon.API.Push.CreateSubscriptionQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Subscription> {
        let response = try await Mastodon.API.Push.createSubscription(
            session: session,
            domain: authenticationContext.domain,
            query: query,
            authorization: authenticationContext.authorization
        )

        return response
    }
    
    public func cancelMastodonNotificationSubscription(
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.EmptySubscription> {
        return try await cancelMastodonNotificationSubscription(
            domain: authenticationContext.domain,
            authorization: authenticationContext.authorization
        )
    }
    
    public func cancelMastodonNotificationSubscription(
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.EmptySubscription> {
        let response = try await Mastodon.API.Push.removeSubscription(
            session: session,
            domain: domain,
            authorization: authorization
        )
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): cancel subscription successful: \(domain), user \(String(describing: authorization.accessToken))")

        return response
    }
    
}
