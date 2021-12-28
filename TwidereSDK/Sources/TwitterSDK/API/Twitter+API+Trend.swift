//
//  Twitter+API+Trend.swift
//  
//
//  Created by MainasuK on 2021-12-28.
//

import Foundation

extension Twitter.API.Trend {
    
    // https://developer.twitter.com/en/docs/twitter-api/v1/trends/trends-for-location/api-reference/get-trends-place
    static let trendsTopicEndpointURL = Twitter.API.endpointURL
        .appendingPathComponent("trends")
        .appendingPathComponent("place.json")
    
    public static func topics(
        session: URLSession,
        query: TopicQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<[TopicResponse]> {
        let request = Twitter.API.request(
            url: trendsTopicEndpointURL,
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: [TopicResponse].self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct TopicQuery: Query {
        public let id: Int
        
        public init(id: Int) {
            self.id = id
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "id", value: "\(id)"))
            guard !items.isEmpty else { return nil }
            return items
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
    public struct TopicResponse: Codable, Hashable {
        public let trends: [Twitter.Entity.Trend]
        public let asOf: Date
        public let createdAt: Date
        public let locations: [Location]
        
        enum CodingKeys: String, CodingKey {
            case trends
            case asOf = "as_of"
            case createdAt = "created_at"
            case locations
        }
        
        public struct Location: Codable, Hashable {
            public let name: String
            public let woeid: Int
        }
    }
}
