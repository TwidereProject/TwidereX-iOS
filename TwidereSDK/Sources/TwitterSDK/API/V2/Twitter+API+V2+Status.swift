//
//  Twitter+API+V2+Status.swift
//  
//
//  Created by MainasuK on 2022-4-21.
//

import Foundation

extension Twitter.API.V2 {
    public enum Status { }
}

// doc: https://developer.twitter.com/en/docs/twitter-api/tweets/manage-tweets/api-reference/post-tweets
extension Twitter.API.V2.Status {
    
    private static var tweetEndpointURL: URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("tweets")
    }
    
    public static func publish(
        session: URLSession,
        query: PublishQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<PublishContent> {
        let request = Twitter.API.request(
            url: tweetEndpointURL,
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: PublishContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct PublishQuery: JSONEncodeQuery {
        
        public let poll: Poll?
        public let forSuperFollowersOnly: Bool?
        public let replySettings: Twitter.Entity.V2.Tweet.ReplySettings?
        public let text: String?
        
        enum CodingKeys: String, CodingKey {
            case poll
            case forSuperFollowersOnly = "for_super_followers_only"
            case replySettings = "reply_settings"
            case text
        }
        
        public init(
            poll: Poll?,
            forSuperFollowersOnly: Bool?,
            replySettings: Twitter.Entity.V2.Tweet.ReplySettings?,
            text: String?
        ) {
            self.poll = poll
            self.forSuperFollowersOnly = forSuperFollowersOnly
            self.text = text
            self.replySettings = replySettings
        }
        
        var queryItems: [URLQueryItem]? { nil }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
    }
    
    public struct PublishContent: Codable {
        public let data: ContentData
        
        public struct ContentData: Codable {
            public let id: String
            public let text: String
        }
    }
    
}

extension Twitter.API.V2.Status {
    public struct Poll: Codable {
        public let options: [String]
        public let durationMinutes: Int
        
        enum CodingKeys: String, CodingKey {
            case options
            case durationMinutes = "duration_minutes"
        }
        
        public init(options: [String], durationMinutes: Int) {
            self.options = options
            self.durationMinutes = durationMinutes
        }
    }
}
