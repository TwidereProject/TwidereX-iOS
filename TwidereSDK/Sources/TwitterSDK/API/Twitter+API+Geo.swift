//
//  Twitter+API+Geo.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-27.
//

import Foundation
import Combine

extension Twitter.API.Geo {
    
    static let searchEndpointURL = Twitter.API.endpointURL.appendingPathComponent("geo/search.json")
    
    public static func search(
        session: URLSession,
        query: SearchQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<SearchResponse> {
        let request = Twitter.API.request(
            url: searchEndpointURL,
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: SearchResponse.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct SearchQuery: Query {
        public let latitude: Double
        public let longitude: Double
        public let granularity: String
        
        public init(
            latitude: Double,
            longitude: Double,
            granularity: String
        ) {
            self.latitude = latitude
            self.longitude = longitude
            self.granularity = granularity
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "lat", value: "\(latitude)"))
            items.append(URLQueryItem(name: "long", value: "\(longitude)"))
            items.append(URLQueryItem(name: "granularity", value: granularity))
            guard !items.isEmpty else { return nil }
            return items
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
    public struct SearchResponse: Codable {
        public let result: Result
        
        public struct Result: Codable {
            public let places: [Twitter.Entity.Place]
        }
    }
}
