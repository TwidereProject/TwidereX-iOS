//
//  Mastodon+API+Notification.swift
//  
//
//  Created by MainasuK on 2021/11/16.
//

import Foundation

extension Mastodon.API.Notification {
    
    static func notificationsEndpointURL(domain: String) -> URL {
        Mastodon.API.endpointURL(domain: domain).appendingPathComponent("notifications")
    }

    /// Get all notifications
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.2
    /// # Last Update
    ///   2021/11/16
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/notifications/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `NotificationsQuery` with query parameters
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Token` nested in the response
    public static func notifications(
        session: URLSession,
        domain: String,
        query: Mastodon.API.Notification.NotificationsQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Notification]> {
        let request = Mastodon.API.request(
            url: notificationsEndpointURL(domain: domain),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.Notification].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public enum TimelineScope: Hashable {
        case all
        case mentions
        
        public var includeTypes: [Mastodon.Entity.Notification.NotificationType]? {
            switch self {
            case .all:
                return nil
            case .mentions:
                return [.mention, .status]
            }   // end switch
        }
        
        public var excludeTypes: [Mastodon.Entity.Notification.NotificationType]? {
            switch self {
            case .all:
                return nil
            case .mentions:
                return [.follow, .followRequest, .reblog, .favourite, .poll]
            }   // end switch
        }
    }
    
    public struct NotificationsQuery: Query {
        
        public let maxID: Mastodon.Entity.Status.ID?
        public let sinceID: Mastodon.Entity.Status.ID?
        public let minID: Mastodon.Entity.Status.ID?
        public let limit: Int?
        public let types: [Mastodon.Entity.Notification.NotificationType]?
        public let excludeTypes: [Mastodon.Entity.Notification.NotificationType]?
        public let accountID: String?
    
        public init(
            maxID: Mastodon.Entity.Status.ID? = nil,
            sinceID: Mastodon.Entity.Status.ID? = nil,
            minID: Mastodon.Entity.Status.ID? = nil,
            limit: Int? = nil,
            types: [Mastodon.Entity.Notification.NotificationType]? = nil,
            excludeTypes: [Mastodon.Entity.Notification.NotificationType]? = nil,
            accountID: String? = nil
        ) {
            self.maxID = maxID
            self.sinceID = sinceID
            self.minID = minID
            self.limit = limit
            self.types = types
            self.excludeTypes = excludeTypes
            self.accountID = accountID
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            maxID.flatMap { items.append(URLQueryItem(name: "max_id", value: $0)) }
            sinceID.flatMap { items.append(URLQueryItem(name: "since_id", value: $0)) }
            minID.flatMap { items.append(URLQueryItem(name: "min_id", value: $0)) }
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            if let types = types {
                types.forEach {
                    items.append(URLQueryItem(name: "types[]", value: $0.rawValue))
                }
            }
            if let excludeTypes = excludeTypes {
                excludeTypes.forEach {
                    items.append(URLQueryItem(name: "exclude_types[]", value: $0.rawValue))
                }
            }
            accountID.flatMap { items.append(URLQueryItem(name: "account_id", value: $0)) }
            guard !items.isEmpty else { return nil }
            return items
        }
        
        var body: Data? { nil }

    }

}

extension Mastodon.API.Notification {
    
    static func notificationEndpointURL(domain: String, notificationID: String) -> URL {
        notificationsEndpointURL(domain: domain).appendingPathComponent(notificationID)
    }
    
    /// Get a single notification
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.2
    /// # Last Update
    ///   2021/11/16
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/notifications/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - notificationID: ID of the notification.
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Token` nested in the response
    public static func notification(
        session: URLSession,
        domain: String,
        notificationID: Mastodon.Entity.Notification.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Notification> {
        let request = Mastodon.API.request(
            url: notificationEndpointURL(domain: domain, notificationID: notificationID),
            method: .GET,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Notification.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
}
