//
//  Twitter+API+Favorites.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-13.
//

import Foundation
import Combine

extension Twitter.API.Favorites {
    static let favoritesCreateEndpointURL = Twitter.API.endpointURL.appendingPathComponent("favorites/create.json")
    static let favoritesDestroyEndpointURL = Twitter.API.endpointURL.appendingPathComponent("favorites/destroy.json")

    public static func favorites(session: URLSession, authorization: Twitter.API.OAuth.Authorization, favoriteKind: FavoriteKind, query: Query) -> AnyPublisher<Twitter.Response<Twitter.Entity.Tweet>, Error> {
        let url: URL = {
            switch favoriteKind {
            case .create: return favoritesCreateEndpointURL
            case .destroy: return favoritesDestroyEndpointURL
            }
        }()
        var request = Twitter.API.request(url: url, httpMethod: "POST", authorization: authorization, queryItems: query.queryItems)
        request.httpMethod = "POST"
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: Twitter.Entity.Tweet.self, from: data, response: response)
                return Twitter.Response(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func favoritesDestroy(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: Query) -> AnyPublisher<Twitter.Response<Twitter.Entity.Tweet>, Error> {
        var request = Twitter.API.request(url: favoritesCreateEndpointURL, httpMethod: "POST", authorization: authorization, queryItems: query.queryItems)
        request.httpMethod = "POST"
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: Twitter.Entity.Tweet.self, from: data, response: response)
                return Twitter.Response(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}

extension Twitter.API.Favorites {
    public enum FavoriteKind {
        case create
        case destroy
    }
    
    public struct Query {
        public let id: Twitter.Entity.Tweet.ID
        
        public init(id: Twitter.Entity.Tweet.ID) {
            self.id = id
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "id", value: id))
            guard !items.isEmpty else { return nil }
            return items
        }
    }
}
