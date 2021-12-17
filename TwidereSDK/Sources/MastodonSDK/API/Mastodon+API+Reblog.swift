//
//  Mastodon+API+Reblog.swift
//  
//
//  Created by Cirno MainasuK on 2021-9-18.
//

import Foundation

extension Mastodon.API.Reblog {
    
    public enum ReblogKind {
        case `do`(query: ReblogQuery)
        case undo
    }
    
    public static func reblog(
        session: URLSession,
        domain: String,
        statusID: Mastodon.Entity.Status.ID,
        reblogKind: ReblogKind,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status>  {
        switch reblogKind {
        case .do(let query):
            return try await reblog(session: session, domain: domain, statusID: statusID, query: query, authorization: authorization)
        case .undo:
            return try await undoReblog(session: session, domain: domain, statusID: statusID, authorization: authorization)
        }
    }
    
}


extension Mastodon.API.Reblog {
    static func reblogEndpointURL(domain: String, statusID: Mastodon.Entity.Status.ID) -> URL {
        let pathComponent = "statuses/" + statusID + "/reblog"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Boost
    ///
    /// Reshare a status.
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
    ///   - statusID: id for status
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Status` nested in the response
    public static func reblog(
        session: URLSession,
        domain: String,
        statusID: Mastodon.Entity.Status.ID,
        query: ReblogQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        let request = Mastodon.API.request(
            url: reblogEndpointURL(domain: domain, statusID: statusID),
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Status.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public typealias Visibility = Mastodon.Entity.Source.Privacy
    
    public struct ReblogQuery: JSONEncodeQuery {
        public let visibility: Visibility?
        
        public init(visibility: Visibility?) {
            self.visibility = visibility
        }
        
        var queryItems: [URLQueryItem]? { nil }
    }
}

extension Mastodon.API.Reblog {
    
    static func unreblogEndpointURL(domain: String, statusID: Mastodon.Entity.Status.ID) -> URL {
        let pathComponent = "statuses/" + statusID + "/unreblog"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Undo reblog
    ///
    /// Undo a reshare of a status.
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
    ///   - statusID: id for status
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Status` nested in the response
    public static func undoReblog(
        session: URLSession,
        domain: String,
        statusID: Mastodon.Entity.Status.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        let request = Mastodon.API.request(
            url: unreblogEndpointURL(domain: domain, statusID: statusID),
            method: .POST,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Status.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
}
