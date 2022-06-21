//
//  Twitter+API+V2+Lookup.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-15.
//

import Foundation
import Combine

extension Twitter.API.V2 {
    public enum Lookup { }
}

// https://developer.twitter.com/en/docs/twitter-api/tweets/lookup/api-reference/get-tweets
extension Twitter.API.V2.Lookup {
    
    static let tweetsEndpointURL = Twitter.API.endpointV2URL.appendingPathComponent("tweets")
    
    public static func statuses(
        session: URLSession,
        query: StatusLookupQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.Lookup.Content> {
        let request = Twitter.API.request(
            url: tweetsEndpointURL,
            method: .GET,
            query: query,
            authorization: authorization
        )
        
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.API.V2.Lookup.Content.self, from: data, response: response)
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
    
    public struct StatusLookupQuery: Query {
        public let statusIDs: [Twitter.Entity.Tweet.ID]
        
        public init(statusIDs: [Twitter.Entity.Tweet.ID]) {
            self.statusIDs = statusIDs
        }
        
        var queryItems: [URLQueryItem]? {
            let ids = statusIDs.joined(separator: ",")
            return [
                Twitter.API.V2.Lookup.expansions.queryItem,
                Twitter.Request.tweetsFields.queryItem,
                Twitter.Request.userFields.queryItem,
                Twitter.Request.mediaFields.queryItem,
                Twitter.Request.placeFields.queryItem,
                Twitter.Request.pollFields.queryItem,
                URLQueryItem(name: "ids", value: ids),
            ]
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
    public struct Content: Codable {
        public let data: [Twitter.Entity.V2.Tweet]?
        public let includes: Include?
        
        public struct Include: Codable {
            public let users: [Twitter.Entity.V2.User]?
            public let tweets: [Twitter.Entity.V2.Tweet]?
            public let media: [Twitter.Entity.V2.Media]?
            public let places: [Twitter.Entity.V2.Place]?
            public let polls: [Twitter.Entity.V2.Tweet.Poll]?
        }
    }
    
}
