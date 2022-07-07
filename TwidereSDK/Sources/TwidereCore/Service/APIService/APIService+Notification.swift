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
 
    func createMastodonNotificationSubscription(
        query: Mastodon.API.Push.CreateSubscriptionQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws {
        
        let response = try await Mastodon.API.Push.createSubscription(
            session: session,
            domain: authenticationContext.domain,
            query: query,
            authorization: authenticationContext.authorization
        )
        
//        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error> in
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: create subscription successful %s", ((#file as NSString).lastPathComponent), #line, #function, response.value.endpoint)
//
//            let managedObjectContext = self.backgroundManagedObjectContext
//            return managedObjectContext.performChanges {
//                guard let subscription = managedObjectContext.object(with: subscriptionObjectID) as? NotificationSubscription else {
//                    assertionFailure()
//                    return
//                }
//                subscription.endpoint = response.value.endpoint
//                subscription.serverKey = response.value.serverKey
//                subscription.userToken = authorization.accessToken
//                subscription.didUpdate(at: response.networkDate)
//            }
//            .setFailureType(to: Error.self)
//            .map { _ in return response }
//            .eraseToAnyPublisher()
//        }
//        .eraseToAnyPublisher()
    }
    
    func cancelMastodonNotificationSubscription(
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.EmptySubscription> {
        let response = try await Mastodon.API.Push.removeSubscription(
            session: session,
            domain: domain,
            authorization: authorization
        )
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): cancel subscription successful: \(domain), \(String(describing: authorization))")

        return response
    }
    
}
