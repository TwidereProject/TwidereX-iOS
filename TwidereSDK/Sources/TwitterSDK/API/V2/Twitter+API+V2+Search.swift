//
//  Twitter+API+V2+Search.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-16.
//

import os.log
import Foundation
import Combine

extension Twitter.API.V2 {
    public enum Search { }
}

/// https://developer.twitter.com/en/docs/twitter-api/tweets/search/api-reference
extension Twitter.API.V2.Search {
    
    static let tweetsSearchRecentEndpointURL = Twitter.API.endpointV2URL.appendingPathComponent("tweets/search/recent")

    public static func recentTweet(
        session: URLSession,
        query: Twitter.API.V2.Search.RecentTweetQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.Search.Content> {
        let request = Twitter.API.request(
            url: tweetsSearchRecentEndpointURL,
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.API.V2.Search.Content.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    static var expansions: [Twitter.Request.Expansions] {
        return [
            .attachmentsPollIDs,
            .attachmentsMediaKeys,
            .authorID,
            .entitiesMentionsUsername,
            .geoPlaceID,
            .inReplyToUserID,
            .referencedTweetsID,
            .referencedTweetsIDAuthorID
        ]
    }

    public struct RecentTweetQuery: Query {
        public let query: String
        public let maxResults: Int
        public let sinceID: Twitter.Entity.V2.Tweet.ID?
        public let startTime: Date?
        public let nextToken: String?
        
        public init(
            query: String,
            maxResults: Int,
            sinceID: Twitter.Entity.V2.Tweet.ID?,
            startTime: Date?,
            nextToken: String?
        ) {
            self.query = query
            self.maxResults = min(100, max(10, maxResults))
            self.sinceID = sinceID
            self.startTime = startTime
            self.nextToken = nextToken
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = [
                Twitter.API.V2.Search.expansions.queryItem,
                Twitter.Request.tweetsFields.queryItem,
                Twitter.Request.userFields.queryItem,
                Twitter.Request.mediaFields.queryItem,
                Twitter.Request.placeFields.queryItem,
                Twitter.Request.pollFields.queryItem,
                URLQueryItem(name: "max_results", value: String(maxResults)),
            ]
            sinceID.flatMap { items.append(URLQueryItem(name: "since_id", value: $0)) }
            nextToken.flatMap { items.append(URLQueryItem(name: "next_token", value: $0)) }
            return items
        }
        var encodedQueryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = [
                URLQueryItem(name: "query", value: query.urlEncoded)
            ]
            if let startTime = startTime {
                let formatter = ISO8601DateFormatter()
                let time = formatter.string(from: startTime)
                let item = URLQueryItem(name: "start_time", value: time.urlEncoded)
                items.append(item)
            }
            return items
        }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
    public struct Content: Codable {
        public let data: [Twitter.Entity.V2.Tweet]?
        public let includes: Include?
        public let meta: Meta
        
        public struct Include: Codable {
            public let users: [Twitter.Entity.V2.User]?
            public let tweets: [Twitter.Entity.V2.Tweet]?
            public let media: [Twitter.Entity.V2.Media]?
            public let places: [Twitter.Entity.V2.Place]?
            public let polls: [Twitter.Entity.V2.Tweet.Poll]?
        }
        
        public struct Meta: Codable {
            public let newestID: String?
            public let oldestID: String?
            public let resultCount: Int
            public let nextToken: String?
            
            public enum CodingKeys: String, CodingKey {
                case newestID = "newest_id"
                case oldestID = "oldest_id"
                case resultCount = "result_count"
                case nextToken = "next_token"
            }
        }
    }
    
}
