//
//  Twitter+API+V2+User+Like.swift
//  Twitter+API+V2+User+Like
//
//  Created by Cirno MainasuK on 2021-9-8.
//

import Foundation

// https://developer.twitter.com/en/docs/twitter-api/tweets/likes/api-reference/post-users-id-likes
extension Twitter.API.V2.User.Like {
    
    static func likeEndpointURL(
        userID: Twitter.Entity.V2.User.ID
    ) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(userID)
            .appendingPathComponent("likes")
    }
    
    public static func like(
        session: URLSession,
        query: LikeQuery,
        userID: Twitter.Entity.V2.User.ID,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<LikeContent> {
        let request = Twitter.API.request(
            url: likeEndpointURL(userID: userID),
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: LikeContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct LikeQuery: JSONEncodeQuery {
        public let tweetID: Twitter.Entity.V2.Tweet.ID
        
        enum CodingKeys: String, CodingKey {
            case tweetID = "tweet_id"
        }
        
        public init(tweetID: Twitter.Entity.V2.Tweet.ID) {
            self.tweetID = tweetID
        }
        
        var queryItems: [URLQueryItem]? { nil }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
    }
    
    public struct LikeContent: Codable {
        public let data: ContentData
        
        public struct ContentData: Codable {
            public let liked: Bool
        }
    }
    
}

extension Twitter.API.V2.User.Like {
    
    static func undoLikeEndpointURL(
        userID: Twitter.Entity.V2.User.ID,
        statusID: Twitter.Entity.V2.Tweet.ID
    ) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(userID)
            .appendingPathComponent("likes")
            .appendingPathComponent(statusID)
    }
    
    public static func undoLike(
        session: URLSession,
        userID: Twitter.Entity.V2.User.ID,
        statusID: Twitter.Entity.V2.Tweet.ID,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<LikeContent> {
        let request = Twitter.API.request(
            url: undoLikeEndpointURL(userID: userID, statusID: statusID),
            method: .DELETE,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: LikeContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
}
