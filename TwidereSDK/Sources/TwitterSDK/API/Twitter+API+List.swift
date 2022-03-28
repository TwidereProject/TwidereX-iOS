//
//  Twitter+API+List.swift
//  
//
//  Created by MainasuK on 2022-3-10.
//

import Foundation
import Combine

extension Twitter.API.List {
    
    static let showEndpointURL = Twitter.API.endpointURL
        .appendingPathComponent("lists")
        .appendingPathComponent("show.json")
    
    public static func show(
        session: URLSession,
        query: ShowQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.Entity.List> {
        let request = Twitter.API.request(
            url: showEndpointURL,
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.Entity.List.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct ShowQuery: Query {
        public let id: Twitter.Entity.List.ID
        
        public init(
            id: Twitter.Entity.List.ID
        ) {
            self.id = id
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "list_id", value: id))
            guard !items.isEmpty else { return nil }
            return items
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
}
