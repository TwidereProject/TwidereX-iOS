//
//  Twitter+API+Geo.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-27.
//

import Foundation
import Combine

extension Twitter.API.Geo {
    
    public static func search(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: SearchQuery) -> AnyPublisher<Twitter.Response.Content<SearchResponse>, Error> {
        fatalError("TODO:")
    }
    
}

extension Twitter.API.Geo {
    public struct SearchQuery {
        public let latitude: Double
        public let longitude: Double
        public let granularity: String
        
        public init(latitude: Double, longitude: Double, granularity: String) {
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
    }
    
    public struct SearchResponse: Codable {
        
    }
}
