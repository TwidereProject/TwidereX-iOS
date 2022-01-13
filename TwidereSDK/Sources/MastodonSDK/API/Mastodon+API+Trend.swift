//
//  Mastodon+API+Trend.swift
//  
//
//  Created by MainasuK on 2022-1-6.
//

import Foundation

extension Mastodon.API.Trend {
    
    static func trendsURL(domain: String) -> URL {
        Mastodon.API.endpointURL(domain: domain).appendingPathComponent("trends")
    }

    /// Trending tags
    ///
    /// Tags that are being used more frequently within the past week.
    ///
    /// Version history:
    /// 3.4.4 - added
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/instance/trends/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: query
    /// - Returns: `Hashtags` nested in the response
    
    public static func tags(
        session: URLSession,
        domain: String,
        query: Mastodon.API.Trend.TrendQuery?
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Tag]> {
        let request = Mastodon.API.request(
            url: trendsURL(domain: domain),
            method: .GET,
            query: query,
            authorization: nil
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.Tag].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public struct TrendQuery: Query {
        
        public let limit: Int? // Maximum number of results to return. Defaults to 10.

        public init(limit: Int?) {
            self.limit = limit
        }

        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            guard !items.isEmpty else { return nil }
            return items
        }
        var body: Data? { nil }
    }
    
}
