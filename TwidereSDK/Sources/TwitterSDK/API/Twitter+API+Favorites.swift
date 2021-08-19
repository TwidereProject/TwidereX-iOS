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
    static let favoritesListEndpointURL = Twitter.API.endpointURL.appendingPathComponent("favorites/list.json")

    public static func favorites(session: URLSession, authorization: Twitter.API.OAuth.Authorization, favoriteKind: FavoriteKind, query: FavoriteQuery) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Tweet>, Error> {
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
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func list(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: Twitter.API.Timeline.TimelineQuery) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
        assert(query.userID != nil && query.userID != "")
        
        let request = Twitter.API.request(url: favoritesListEndpointURL, httpMethod: "GET", authorization: authorization, queryItems: query.queryItems)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: [Twitter.Entity.Tweet].self, from: data, response: response)
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }


}

extension Twitter.API.Favorites {
    
    public enum FavoriteKind {
        case create
        case destroy
    }
    
    public struct FavoriteQuery {
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
    
    public struct ListQuery {
        public let count: Int?
        public let userID: String?
        public let maxID: String?
        
        public init(count: Int? = nil, userID: Twitter.Entity.User.ID? = nil, maxID: String? = nil) {
            self.count = count
            self.userID = userID
            self.maxID = maxID
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            if let count = self.count {
                items.append(URLQueryItem(name: "count", value: String(count)))
            }
            if let userID = self.userID {
                items.append(URLQueryItem(name: "user_id", value: userID))
            }
            if let maxID = self.maxID {
                items.append(URLQueryItem(name: "max_id", value: maxID))
            }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
}
