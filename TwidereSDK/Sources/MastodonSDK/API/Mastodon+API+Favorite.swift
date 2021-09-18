//
//  Mastodon+API+Favorite.swift
//  
//
//  Created by Cirno MainasuK on 2021-9-18.
//

import Foundation

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
