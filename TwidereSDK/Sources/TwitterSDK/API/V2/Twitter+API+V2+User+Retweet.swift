//
//  Twitter+API+V2+User+Retweet.swift
//  Twitter+API+V2+User+Retweet
//
//  Created by Cirno MainasuK on 2021-9-8.
//

import Foundation

extension Twitter.API.V2.User {
    public enum Retweet { }
}

extension Twitter.API.V2.User.Retweet {
    
    static func retweetEndpointURL(
        userID: Twitter.Entity.V2.User.ID
    ) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(userID)
            .appendingPathComponent("retweets")
    }

    public static func retweet(
        session: URLSession,
        query: RetweetQuery,
        userID: Twitter.Entity.V2.User.ID,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<RetweetContent> {
        let request = Twitter.API.request(
            url: retweetEndpointURL(userID: userID),
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: RetweetContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct RetweetQuery: JSONEncodeQuery {
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
    
    public struct RetweetContent: Codable {
        public let data: ContentData
        
        public struct ContentData: Codable {
            public let retweeted: Bool
        }
    }

}

extension Twitter.API.V2.User.Retweet {

    static func undoRetweetEndpointURL(
        userID: Twitter.Entity.V2.User.ID,
        statusID: Twitter.Entity.V2.Tweet.ID
    ) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(userID)
            .appendingPathComponent("retweets")
            .appendingPathComponent(statusID)
    }
    
    public static func undoRetweet(
        session: URLSession,
        userID: Twitter.Entity.V2.User.ID,
        statusID: Twitter.Entity.V2.Tweet.ID,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<RetweetContent> {
        let request = Twitter.API.request(
            url: undoRetweetEndpointURL(userID: userID, statusID: statusID),
            method: .DELETE,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: RetweetContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
}
