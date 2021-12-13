//
//  Twitter+API+Lookup.swift
//  
//
//  Created by Cirno MainasuK on 2020-12-15.
//

import Foundation
import Combine

extension Twitter.API.Lookup {
    
    static let statusesLookupEndpointURL = Twitter.API.endpointURL.appendingPathComponent("statuses/lookup.json")
    
    public static func tweets(
        session: URLSession,
        query: LookupQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.Tweet]> {
        let request = Twitter.API.request(
            url: statusesLookupEndpointURL,
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: [Twitter.Entity.Tweet].self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }

    public struct LookupQuery: Query {
        public let ids: [String]
        
        public init(ids: [String]) {
            self.ids = ids
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            
            let ids = self.ids.joined(separator: ",")
            // "id" not typo
            items.append(URLQueryItem(name: "id", value: ids))
            items.append(URLQueryItem(name: "include_entities", value: "true"))
            items.append(URLQueryItem(name: "include_ext_alt_text", value: "true"))
            items.append(URLQueryItem(name: "tweet_mode", value: "extended"))
            
            guard !items.isEmpty else { return nil }
            return items
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
}
