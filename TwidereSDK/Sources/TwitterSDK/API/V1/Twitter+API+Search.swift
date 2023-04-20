//
//  Twitter+API+Search.swift
//  
//
//  Created by Cirno MainasuK on 2021-1-20.
//

import Foundation
import Combine

extension Twitter.API.Search {

    static var tweetsEndpointURL = Twitter.API.endpointURL.appendingPathComponent("search/tweets.json")

    public static func tweets(
        session: URLSession,
        query: Twitter.API.Statuses.Timeline.TimelineQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.Search.Content> {
        let request = Twitter.API.request(
            url: tweetsEndpointURL,
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.API.Search.Content.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }

}

extension Twitter.API.Search {
    public class Content: Codable {
        
        public let statuses: [Twitter.Entity.Tweet]?
        public let searchMetadata: SearchMetadata
        
        public enum CodingKeys: String, CodingKey {
            case statuses
            case searchMetadata = "search_metadata"
        }
        
        public struct SearchMetadata: Codable {
            public let nextResults: String?
            public let query: String
            public let count: Int
            
            public enum CodingKeys: String, CodingKey {
                case nextResults = "next_results"
                case query
                case count
            }
        }
        
    }
}
