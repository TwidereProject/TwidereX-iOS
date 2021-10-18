//
//  Mastodon+API+Favorite.swift
//  
//
//  Created by Cirno MainasuK on 2021-9-18.
//

import Foundation

extension Mastodon.API.Favorite {
    
    static func favoritesStatusesEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("favourites")
    }
    
    /// Favourited statuses
    ///
    /// Using this endpoint to view the favourited list for user
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/10/18
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/favourites/)
    /// - Parameters:
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - session: `URLSession`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Server` nested in the response
    public static func statuses(
        session: URLSession,
        domain: String,
        query: Mastodon.API.Favorite.FavoriteStatusesQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let url = favoritesStatusesEndpointURL(domain: domain)
        let request = Mastodon.API.request(
            url: url,
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.Status].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public struct FavoriteStatusesQuery: Query, TimelineQueryType {
        public var limit: Int?
        public var minID: Mastodon.Entity.Status.ID?
        public var maxID: Mastodon.Entity.Status.ID?
        public var sinceID: Mastodon.Entity.Status.ID?
        
        public init(
            limit: Int? = nil,
            minID: Mastodon.Entity.Status.ID? = nil,
            maxID: Mastodon.Entity.Status.ID? = nil,
            sinceID: Mastodon.Entity.Status.ID? = nil
        ) {
            self.limit = limit
            self.minID = minID
            self.maxID = maxID
            self.sinceID = sinceID
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            if let limit = self.limit {
                items.append(URLQueryItem(name: "limit", value: String(limit)))
            }
            if let minID = self.minID {
                items.append(URLQueryItem(name: "min_id", value: minID))
            }
            if let maxID = self.maxID {
                items.append(URLQueryItem(name: "max_id", value: maxID))
            }
            if let sinceID = self.sinceID {
                items.append(URLQueryItem(name: "since_id", value: sinceID))
            }
            guard !items.isEmpty else { return nil }
            return items
        }
        
        var body: Data? { nil }
    }
    
}

extension Mastodon.API.Favorite {
    
    static func favoriteActionEndpointURL(domain: String, statusID: String, favoriteKind: FavoriteKind) -> URL {
        let actionString: String = {
            switch favoriteKind {
            case .do:   return "/favourite"
            case .undo: return "/unfavourite"
            }
        }()
        let pathComponent = "statuses/" + statusID + actionString
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    public enum FavoriteKind {
        case `do`
        case undo
    }
    
    /// Favorite / Undo Favorite
    ///
    /// Add a status to your favourites list / Remove a status from your favourites list
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.0
    /// # Last Update
    ///   2021/9/18
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - statusID: Mastodon status id
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Server` nested in the response
    public static func favorites(
        session: URLSession,
        domain: String,
        statusID: String,
        favoriteKind: FavoriteKind,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        let request = Mastodon.API.request(
            url: favoriteActionEndpointURL(domain: domain, statusID: statusID, favoriteKind: favoriteKind),
            method: .POST,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Status.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }

}
