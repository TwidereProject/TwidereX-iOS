//
//  Twitter+API+V2+Search.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-16.
//

import os.log
import Foundation
import Combine

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
    
    @available(*, deprecated, message: "")
    public static func tweetsSearchRecent(
        query: Twitter.API.V2.Search.RecentQuery,
        session: URLSession,
        authorization: Twitter.API.OAuth.Authorization
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.Search.Content>, Error> {
        guard var components = URLComponents(string: tweetsSearchRecentEndpointURL.absoluteString) else { fatalError() }
        
        components.queryItems = [
            Twitter.API.V2.Search.expansions.queryItem,
            Twitter.Request.tweetsFields.queryItem,
            Twitter.Request.userFields.queryItem,
            Twitter.Request.mediaFields.queryItem,
            Twitter.Request.placeFields.queryItem,
            URLQueryItem(name: "max_results", value: String(query.maxResults)),
        ]
        query.sinceID.flatMap { components.queryItems?.append(URLQueryItem(name: "since_id", value: $0)) }
        query.nextToken.flatMap { components.queryItems?.append(URLQueryItem(name: "next_token", value: $0)) }
        var encodedQueryItems: [URLQueryItem] = [
            URLQueryItem(name: "query", value: query.query.urlEncoded)
        ]
        if let startTime = query.startTime {
            let formatter = ISO8601DateFormatter()
            let time = formatter.string(from: startTime)
            let item = URLQueryItem(name: "start_time", value: time.urlEncoded)
            encodedQueryItems.append(item)
        }
        components.percentEncodedQueryItems = (components.percentEncodedQueryItems ?? []) + encodedQueryItems
        
        guard let requestURL = components.url else { fatalError() }
        var request = URLRequest(
            url: requestURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: Twitter.API.timeoutInterval
        )
        request.setValue(
            authorization.authorizationHeader(requestURL: requestURL, httpMethod: "GET"),
            forHTTPHeaderField: Twitter.API.OAuth.authorizationField
        )
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                do {
                    let value = try Twitter.API.decode(type: Twitter.API.V2.Search.Content.self, from: data, response: response)
                    return Twitter.Response.Content(value: value, response: response)
                } catch {
                    debugPrint(error)
                    os_log("%{public}s[%{public}ld], %{public}s: decode fail. error: %s. data: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription, String(data: data, encoding: .utf8) ?? "<nil>")
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }

}

extension Twitter.API.V2.Search {
    
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
    
    @available(*, deprecated, message: "")
    public struct RecentQuery {
        public let query: String
        public let maxResults: Int
        public let sinceID: Twitter.Entity.V2.Tweet.ID?
        public let startTime: Date?
        public let nextToken: String?
        
        public init(query: String, maxResults: Int, sinceID: Twitter.Entity.V2.Tweet.ID?, startTime: Date?, nextToken: String?) {
            self.query = query
            self.maxResults = min(100, max(10, maxResults)) 
            self.sinceID = sinceID
            self.startTime = startTime
            self.nextToken = nextToken
        }
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
