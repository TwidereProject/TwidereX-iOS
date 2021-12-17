//
//  Mastodon+API+Account.swift
//  
//
//  Created by Cirno MainasuK on 2021-10-15.
//

import Foundation

extension Mastodon.API.Account {

    static func accountsInfoEndpointURL(domain: String, id: Mastodon.Entity.Account.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("accounts")
            .appendingPathComponent(id)
    }

    /// Retrieve information
    ///
    /// View information about a profile.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.2
    /// # Last Update
    ///   2021/12/8
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `AccountInfoQuery` with account query information,
    ///   - authorization: user token
    /// - Returns: `Account` nested in the response
    public static func account(
        session: URLSession,
        domain: String,
        userID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization?
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Account> {
        let request = Mastodon.API.request(
            url: accountsInfoEndpointURL(domain: domain, id: userID),
            method: .GET,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Account.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
}

extension Mastodon.API.Account {
    
    static func accountStatusesEndpointURL(domain: String, accountID: Mastodon.Entity.Account.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts/\(accountID)/statuses")
    }
    
    /// View statuses from followed users.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/3/30
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `AccountStatusesQuery` with query parameters
    ///   - authorization: User token
    /// - Returns: `[Status]` nested in the response
    public static func statuses(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        query: AccountStatusesQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let request = Mastodon.API.request(
            url: accountStatusesEndpointURL(domain: domain, accountID: accountID),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.Status].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public struct AccountStatusesQuery: Query {
        
        public let maxID: Mastodon.Entity.Status.ID?
        public let sinceID: Mastodon.Entity.Status.ID?
        public let excludeReplies: Bool?    // undocumented
        public let excludeReblogs: Bool?
        public let onlyMedia: Bool?
        public let limit: Int?
        
        public init(
            maxID: Mastodon.Entity.Status.ID?,
            sinceID: Mastodon.Entity.Status.ID?,
            excludeReplies: Bool?,
            excludeReblogs: Bool?,
            onlyMedia: Bool?,
            limit: Int?
        ) {
            self.maxID = maxID
            self.sinceID = sinceID
            self.excludeReplies = excludeReplies
            self.excludeReblogs = excludeReblogs
            self.onlyMedia = onlyMedia
            self.limit = limit
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            maxID.flatMap { items.append(URLQueryItem(name: "max_id", value: $0)) }
            sinceID.flatMap { items.append(URLQueryItem(name: "since_id", value: $0)) }
            excludeReplies.flatMap { items.append(URLQueryItem(name: "exclude_replies", value: $0.queryItemValue)) }
            excludeReblogs.flatMap { items.append(URLQueryItem(name: "exclude_reblogs", value: $0.queryItemValue)) }
            onlyMedia.flatMap { items.append(URLQueryItem(name: "only_media", value: $0.queryItemValue)) }
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            guard !items.isEmpty else { return nil }
            return items
        }
        
        var body: Data? { nil }
    }
    
}
