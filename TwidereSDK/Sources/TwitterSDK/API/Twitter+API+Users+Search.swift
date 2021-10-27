//
//  Twitter+API+Users+Search.swift
//  
//
//  Created by Cirno MainasuK on 2021-10-25.
//

import Foundation

extension Twitter.API.Users {

    static let searchEndpointURL = Twitter.API.endpointURL.appendingPathComponent("users/search.json")

    public static func search(
        session: URLSession,
        query: SearchQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.User]> {
        let request = Twitter.API.request(
            url: searchEndpointURL,
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: [Twitter.Entity.User].self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct SearchQuery: Query {
        public let q: String
        public let page: Int
        public let count: Int
        
        public init(
            q: String, 
            page: Int, 
            count: Int
        ) {
            self.q = q
            self.page = page
            self.count = min(count, 1000)
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "q", value: q))
            items.append(URLQueryItem(name: "page", value: "\(page)"))
            items.append(URLQueryItem(name: "count", value: "\(count)"))
            guard !items.isEmpty else { return nil }
            return items
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
}
