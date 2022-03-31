//
//  Mastodon+API+Account+Search.swift
//  
//
//  Created by MainasuK on 2022-3-23.
//

import Foundation

extension Mastodon.API.Account {
    
    private static func searchEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("accounts")
            .appendingPathComponent("search")
    }
    
    /// Search for matching accounts
    ///
    /// Search for matching accounts by username or display name.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.6
    /// # Last Update
    ///   2022/3/23
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `SearchQuery`
    ///   - authorization: User token
    /// - Returns: `[Account]` nested in the response
    public static func search(
        session: URLSession,
        domain: String,
        query: SearchQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let request = Mastodon.API.request(
            url: searchEndpointURL(domain: domain),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.Account].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public struct SearchQuery: Query {
        public let q: String
        public let limit: Int?
        public let resolve: Bool?
        public let following: Bool?
        
        public init(
            q: String,
            limit: Int?,
            resolve: Bool?,
            following: Bool?
        ) {
            self.q = q
            self.limit = limit
            self.resolve = resolve
            self.following = following
        }
    
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "q", value: q))
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: "\($0)")) }
            resolve.flatMap { items.append(URLQueryItem(name: "resolve", value: $0.queryItemValue)) }
            following.flatMap { items.append(URLQueryItem(name: "following", value: $0.queryItemValue)) }
            guard !items.isEmpty else { return nil }
            return items
        }
        
        var body: Data? { nil }
    }
    
}
