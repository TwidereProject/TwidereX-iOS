//
//  Mastodon+API+V2+Search.swift
//  
//
//  Created by Cirno MainasuK on 2021-10-25.
//

import Foundation

extension Mastodon.API.V2.Search {
    
    static func searchURL(domain: String) -> URL {
        Mastodon.API.endpointV2URL(domain: domain).appendingPathComponent("search")
    }
    
    /// Search results
    ///
    /// Search for content in accounts, statuses and hashtags.
    ///
    /// Version history:
    /// 2.4.1 - added, limit hardcoded to 5
    /// 2.8.0 - add type, limit, offset, min_id, max_id, account_id
    /// 3.0.0 - add exclude_unreviewed param
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/search/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: search query
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `SearchResult` nested in the response
    public static func search(
        session: URLSession,
        domain: String,
        query: SearchQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.SearchResult> {
        let request = Mastodon.API.request(
            url: searchURL(domain: domain),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.SearchResult.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public struct SearchQuery: Query {
        public let accountID: Mastodon.Entity.Account.ID?
        public let maxID: Mastodon.Entity.Status.ID?
        public let minID: Mastodon.Entity.Status.ID?
        public let type: SearchType?
        public let excludeUnreviewed: Bool? // Filter out unreviewed tags? Defaults to false. Use true when trying to find trending tags.
        public let q: String
        public let resolve: Bool? // Attempt WebFinger lookup. Defaults to false.
        public let limit: Int? // Maximum number of results to load, per type. Defaults to 20. Max 40.
        public let offset: Int? // Offset in search results. Used for pagination. Defaults to 0.
        public let following: Bool? // Only include accounts that the user is following. Defaults to false.
        
        public init(
            type: SearchType? = nil,
            accountID: Mastodon.Entity.Account.ID? = nil,
            maxID: Mastodon.Entity.Status.ID? = nil,
            minID: Mastodon.Entity.Status.ID? = nil,
            excludeUnreviewed: Bool? = nil,
            q: String,
            resolve: Bool? = true,
            limit: Int? = nil,
            offset: Int? = nil,
            following: Bool? = nil
        ) {
            
            self.accountID = accountID
            self.maxID = maxID
            self.minID = minID
            self.type = type
            self.excludeUnreviewed = excludeUnreviewed
            self.q = q
            self.resolve = resolve
            self.limit = limit
            self.offset = offset
            self.following = following
        }
        
        public enum SearchType: String, Codable {
            case accounts
            case hashtags
            case statuses
            case `default`
            
            public var rawValue: String {
                switch self {
                case .accounts:
                    return "accounts"
                case .hashtags:
                    return "hashtags"
                case .statuses:
                    return "statuses"
                case .default:
                    return ""
                }
            }
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            accountID.flatMap { items.append(URLQueryItem(name: "account_id", value: $0)) }
            maxID.flatMap { items.append(URLQueryItem(name: "max_id", value: $0)) }
            minID.flatMap { items.append(URLQueryItem(name: "min_id", value: $0)) }
            type.flatMap { items.append(URLQueryItem(name: "type", value: $0.rawValue)) }
            excludeUnreviewed.flatMap { items.append(URLQueryItem(name: "exclude_unreviewed", value: $0.queryItemValue)) }
            items.append(URLQueryItem(name: "q", value: q))
            resolve.flatMap { items.append(URLQueryItem(name: "resolve", value: $0.queryItemValue)) }
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            offset.flatMap { items.append(URLQueryItem(name: "offset", value: String($0))) }
            following.flatMap { items.append(URLQueryItem(name: "following", value: $0.queryItemValue)) }
            guard !items.isEmpty else { return nil }
            return items
        }
        
        var body: Data? { nil }
    }
    
}
