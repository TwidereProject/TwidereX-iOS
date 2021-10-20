//
//  Mastodon+API+Account+Relationship.swift
//  
//
//  Created by Cirno MainasuK on 2021-10-20.
//

import Foundation

extension Mastodon.API.Account {
    
    static func relationshipsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts/relationships")
    }
    
    /// Check relationships to other accounts
    ///
    /// Find out whether a given account is followed, blocked, muted, etc.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.1
    /// # Last Update
    ///   2021/10/20
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/#perform-actions-on-an-account/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `RelationshipQuery`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `[Relationship]` nested in the response
    public static func relationships(
        session: URLSession,
        domain: String,
        query: RelationshipQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Relationship]> {
        let request = Mastodon.API.request(
            url: relationshipsEndpointURL(domain: domain),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.Relationship].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public struct RelationshipQuery: Query {
        public let ids: [Mastodon.Entity.Account.ID]
        
        public init(ids: [Mastodon.Entity.Account.ID]) {
            self.ids = ids
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            for id in ids {
                items.append(URLQueryItem(name: "id[]", value: id))
            }
            guard !items.isEmpty else { return nil }
            return items
        }
        
        var body: Data? { nil }
    }
    
}

extension Mastodon.API.Account {
    
    static func followEndpointURL(domain: String, accountID: Mastodon.Entity.Account.ID) -> URL {
        let pathComponent = "accounts/" + accountID + "/follow"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
//    public enum FollowQueryType {
//        case follow(query: FollowQuery)
//        case unfollow
//    }
    
    
    /// Follow
    ///
    /// Follow the given account. Can also be used to update whether to show reblogs or enable notifications.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.1
    /// # Last Update
    ///   2021/10/20
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - accountID: id for account
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Relationship` nested in the response
    public static func follow(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let query = FollowQuery()
        let request = Mastodon.API.request(
            url: followEndpointURL(domain: domain, accountID: accountID),
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Relationship.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public struct FollowQuery: JSONEncodeQuery {
        public let reblogs: Bool?
        public let notify: Bool?
        
        public init(
            reblogs: Bool? = nil,
            notify: Bool? = nil
        ) {
            self.reblogs = reblogs
            self.notify = notify
        }
        
        var queryItems: [URLQueryItem]? { nil }
    }
    
}

extension Mastodon.API.Account {

    static func unfollowEndpointURL(domain: String, accountID: Mastodon.Entity.Account.ID) -> URL {
        let pathComponent = "accounts/" + accountID + "/unfollow"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Unfollow
    ///
    /// Unfollow the given account.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.1
    /// # Last Update
    ///   2021/10/20
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - accountID: id for account
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Relationship` nested in the response
    public static func unfollow(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let request = Mastodon.API.request(
            url: unfollowEndpointURL(domain: domain, accountID: accountID),
            method: .POST,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Relationship.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }

}
