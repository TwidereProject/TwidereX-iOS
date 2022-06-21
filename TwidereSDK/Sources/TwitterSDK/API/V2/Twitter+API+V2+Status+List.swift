//
//  Twitter+API+V2+Status+List.swift
//  
//
//  Created by MainasuK on 2022-3-2.
//

import Foundation

extension Twitter.API.V2.Status {
    public enum List { }
}

// List Tweets Lookup
// https://developer.twitter.com/en/docs/twitter-api/lists/list-tweets/api-reference/get-lists-id-tweets
extension Twitter.API.V2.Status.List {

    static func tweetsEndpointURL(listID: Twitter.Entity.V2.List.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("lists")
            .appendingPathComponent(listID)
            .appendingPathComponent("tweets")
    }
    
    public static func statuses(
        session: URLSession,
        listID: Twitter.Entity.V2.List.ID,
        query: StatusesQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.Status.List.StatusesContent> {
        let request = Twitter.API.request(
            url: tweetsEndpointURL(listID: listID),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: StatusesContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct StatusesQuery: Query {
        public let maxResults: Int
        public let nextToken: String?
        
        public init(
            maxResults: Int = 20,
            nextToken: String?
        ) {
            self.maxResults = min(100, max(10, maxResults))
            self.nextToken = nextToken
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = [
                [Twitter.Request.Expansions.authorID].queryItem,
                Twitter.Request.userFields.queryItem,
                Twitter.Request.tweetsFields.queryItem,
                URLQueryItem(name: "max_results", value: String(maxResults)),
            ]
            if let nextToken = nextToken {
                let item = URLQueryItem(name: "pagination_token", value: nextToken)
                items.append(item)
            }
            return items
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
    public struct StatusesContent: Codable {
        public let data: [Twitter.Entity.V2.Tweet]?
        public let includes: Includes?
        public let meta: Meta
        
        public struct Includes: Codable {
            public let users: [Twitter.Entity.V2.User]
        }
        
        public struct Meta: Codable {
            public let resultCount: Int
            public let previousToken: String?
            public let nextToken: String?
            
            enum CodingKeys: String, CodingKey {
                case resultCount = "result_count"
                case previousToken = "previous_token"
                case nextToken = "next_token"
            }
        }
    }

}
