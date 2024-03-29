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
