//
//  Mastodon+API+Push.swift
//  
//
//  Created by MainasuK on 2022-7-7.
//

import Foundation

extension Mastodon.API {
    public enum Push { }
}

extension Mastodon.API.Push {
    
    private static func subscriptionEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("push")
            .appendingPathComponent("subscription")
    }
    
    /// Get current subscription
    ///
    /// Using this endpoint to get current subscription
    ///
    /// - Since: 2.4.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/25
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/notifications/push/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `Subscription` nested in the response
    public static func subscription(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Subscription> {
        let request = Mastodon.API.request(
            url: subscriptionEndpointURL(domain: domain),
            method: .GET,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Subscription.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
}

extension Mastodon.API.Push {
    
    /// Subscribe to push notifications
    ///
    /// Add a Web Push API subscription to receive notifications. Each access token can have one push subscription. If you create a new subscription, the old subscription is deleted.
    ///
    /// - Since: 2.4.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/25
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/notifications/push/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `Subscription` nested in the response
    public static func createSubscription(
        session: URLSession,
        domain: String,
        query: CreateSubscriptionQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Subscription> {
        let request = Mastodon.API.request(
            url: subscriptionEndpointURL(domain: domain),
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Subscription.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public struct CreateSubscriptionQuery: JSONEncodeQuery {
        let subscription: QuerySubscription
        let data: QueryData

        public init(
            subscription: Mastodon.API.Push.QuerySubscription,
            data: Mastodon.API.Push.QueryData
        ) {
            self.subscription = subscription
            self.data = data
        }
        
        var queryItems: [URLQueryItem]? { nil }
    }
    
}

extension Mastodon.API.Push {
    
    /// Change types of notifications
    ///
    /// Updates the current push subscription. Only the data part can be updated. To change fundamentals, a new subscription must be created instead.
    ///
    /// - Since: 2.4.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/25
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/notifications/push/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `Subscription` nested in the response
    public static func updateSubscription(
        session: URLSession,
        domain: String,
        query: UpdateSubscriptionQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Subscription> {
        let request = Mastodon.API.request(
            url: subscriptionEndpointURL(domain: domain),
            method: .PUT,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Subscription.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public struct UpdateSubscriptionQuery: JSONEncodeQuery {
        
        let data: QueryData
                
        public init(data: Mastodon.API.Push.QueryData) {
            self.data = data
        }
        
        var queryItems: [URLQueryItem]? { nil }
    }
    
}

extension Mastodon.API.Push {
    
    /// Remove current subscription
    ///
    /// Removes the current Web Push API subscription.
    ///
    /// - Since: 2.4.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/26
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/notifications/push/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `Subscription` nested in the response
    public static func removeSubscription(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.EmptySubscription> {
        let request = Mastodon.API.request(
            url: subscriptionEndpointURL(domain: domain),
            method: .DELETE,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.EmptySubscription.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
 
}

extension Mastodon.API.Push {
        
    public struct QuerySubscription: Codable {
        public let endpoint: String
        public let keys: Keys
        
        public init(
            endpoint: String,
            keys: Keys
        ) {
            self.endpoint = endpoint
            self.keys = keys
        }
        
        public struct Keys: Codable {
            let p256dh: String
            let auth: String
            
            public init(p256dh: Data, auth: Data) {
                self.p256dh = p256dh.base64UrlEncodedString()
                self.auth = auth.base64UrlEncodedString()
            }
        }
    }
    
    public struct QueryData: Codable {
        let alerts: Alerts
        
        public init(alerts: Mastodon.API.Push.QueryData.Alerts) {
            self.alerts = alerts
        }
        
        public struct Alerts: Codable {
            let favourite: Bool?
            let follow: Bool?
            let reblog: Bool?
            let mention: Bool?
            let poll: Bool?

            public init(favourite: Bool?, follow: Bool?, reblog: Bool?, mention: Bool?, poll: Bool?) {
                self.favourite = favourite
                self.follow = follow
                self.reblog = reblog
                self.mention = mention
                self.poll = poll
            }
        }
    }

}
