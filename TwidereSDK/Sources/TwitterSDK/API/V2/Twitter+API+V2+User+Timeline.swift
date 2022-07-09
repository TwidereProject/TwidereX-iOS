//
//  Twitter+API+V2+User+Timeline.swift
//  
//
//  Created by MainasuK on 2022-6-6.
//

import Foundation

extension Twitter.API.V2.User {
    public enum Timeline { }
}

// Home
// https://developer.twitter.com/en/docs/twitter-api/tweets/timelines/api-reference/get-users-id-reverse-chronological
extension Twitter.API.V2.User.Timeline {
 
    private static func homeTimelineEndpointURL(userID: Twitter.Entity.V2.User.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(userID)
            .appendingPathComponent("timelines")
            .appendingPathComponent("reverse_chronological")
    }
    
    public static func home(
        session: URLSession,
        userID: Twitter.Entity.V2.User.ID,
        query: HomeQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Timeline.HomeContent> {
        let request = Twitter.API.request(
            url: homeTimelineEndpointURL(userID: userID),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: HomeContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    static var homeQueryExpansions: [Twitter.Request.Expansions] {
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
    
    public struct HomeQuery: Query {
        
        public let sinceID: Twitter.Entity.V2.Tweet.ID?
        public let untilID: Twitter.Entity.V2.Tweet.ID?
        public let paginationToken: String?
        public let maxResults: Int?
        
        public init(
            sinceID: Twitter.Entity.V2.Tweet.ID?,
            untilID: Twitter.Entity.V2.Tweet.ID?,
            paginationToken: String?,
            maxResults: Int?
        ) {
            self.sinceID = sinceID
            self.untilID = untilID
            self.paginationToken = paginationToken
            self.maxResults = maxResults
        }
        
        var queryItems: [URLQueryItem]? {
            var queryItems: [URLQueryItem] = [
                Twitter.API.V2.User.Timeline.homeQueryExpansions.queryItem,
                Twitter.Request.tweetsFields.queryItem,
                Twitter.Request.userFields.queryItem,
                Twitter.Request.mediaFields.queryItem,
                Twitter.Request.placeFields.queryItem,
                Twitter.Request.pollFields.queryItem,
            ]
            sinceID.flatMap {
                queryItems.append(URLQueryItem(name: "since_id", value: $0))
            }
            untilID.flatMap {
                queryItems.append(URLQueryItem(name: "until_id", value: $0))
            }
            paginationToken.flatMap {
                queryItems.append(URLQueryItem(name: "pagination_token", value: $0))
            }
            maxResults.flatMap {
                queryItems.append(URLQueryItem(name: "max_results", value: String($0)))
            }
            guard !queryItems.isEmpty else { return nil }
            return queryItems
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
    public struct HomeContent: Codable {
        public let data: [Twitter.Entity.V2.Tweet]?
        public let includes: Includes?
        public let meta: Meta
        
        public struct Includes: Codable {
            public let tweets: [Twitter.Entity.V2.Tweet]?
            public let users: [Twitter.Entity.V2.User]?
            public let media: [Twitter.Entity.V2.Media]?
            public let places: [Twitter.Entity.V2.Place]?
            public let polls: [Twitter.Entity.V2.Tweet.Poll]?
        }
        
        public struct Meta: Codable {
            public let resultCount: Int
            public let newestID: Twitter.Entity.V2.Tweet.ID?
            public let oldestID: Twitter.Entity.V2.Tweet.ID?
            public let previousToken: String?
            public let nextToken: String?
            
            enum CodingKeys: String, CodingKey {
                case resultCount = "result_count"
                case newestID = "newest_id"
                case oldestID = "oldest_id"
                case previousToken = "previous_token"
                case nextToken = "next_token"
            }
        }
    }
    
}

// Tweets
// https://developer.twitter.com/en/docs/twitter-api/tweets/timelines/api-reference/get-users-id-tweets
extension Twitter.API.V2.User.Timeline {
 
    private static func tweetsTimelineEndpointURL(userID: Twitter.Entity.V2.User.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(userID)
            .appendingPathComponent("tweets")
    }
    
    public static func tweets(
        session: URLSession,
        userID: Twitter.Entity.V2.User.ID,
        query: TweetsQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Timeline.TweetsContent> {
        let request = Twitter.API.request(
            url: tweetsTimelineEndpointURL(userID: userID),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: HomeContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    static var tweetsQueryExpansions: [Twitter.Request.Expansions] {
        return homeQueryExpansions
    }
    
    public typealias TweetsQuery = HomeQuery
    
    public typealias TweetsContent = HomeContent
    
}

// Likes
// https://developer.twitter.com/en/docs/twitter-api/tweets/likes/api-reference/get-users-id-liked_tweets
extension Twitter.API.V2.User.Timeline {
    
    private static func likedTweetsTimelineEndpointURL(userID: Twitter.Entity.V2.User.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(userID)
            .appendingPathComponent("liked_tweets")
    }
    
    public static func likes(
        session: URLSession,
        userID: Twitter.Entity.V2.User.ID,
        query: TweetsQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Timeline.TweetsContent> {
        let request = Twitter.API.request(
            url: likedTweetsTimelineEndpointURL(userID: userID),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: HomeContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    static var likesQueryExpansions: [Twitter.Request.Expansions] {
        return homeQueryExpansions
    }
    
    public typealias LikesQuery = HomeQuery
    
    public typealias LikesContent = HomeContent
    
}
