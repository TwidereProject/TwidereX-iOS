//
//  Mastodon+API+App.swift
//  Mastodon+API+App
//
//  Created by MainasuK Cirno on 2021/8/17.
//

import Foundation

extension Mastodon.API.App {

    static func appEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("apps")
    }
    
    /// Create an application
    ///
    /// Using this endpoint to obtain `client_id` and `client_secret` for later OAuth token exchange
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.1
    /// # Last Update
    ///   2021/8/17
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/apps/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `CreateQuery`
    /// - Returns: `AnyPublisher` contains `Application` nested in the response
    public static func create(
        session: URLSession,
        domain: String,
        query: CreateQuery
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Application> {
        let request = Mastodon.API.request(
            url: appEndpointURL(domain: domain),
            method: .POST,
            query: query,
            authorization: nil
        )
        
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Application.self, from: data, response: response)
        
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    
    public struct CreateQuery: JSONEncodeQuery {
                
        public let clientName: String
        public let redirectURIs: String
        public let scopes: String?
        public let website: String?
        
        enum CodingKeys: String, CodingKey {
            case clientName = "client_name"
            case redirectURIs = "redirect_uris"
            case scopes
            case website
        }
        
        public init(
            clientName: String,
            redirectURIs: String,
            scopes: String? = "read write follow push",
            website: String?
        ) {
            self.clientName = clientName
            self.redirectURIs = redirectURIs
            self.scopes = scopes
            self.website = website
        }
        
        var queryItems: [URLQueryItem]? { nil }
    }
    
}

extension Mastodon.API.App {

    static func verifyCredentialsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("apps/verify_credentials")
    }
    
    /// Verify application token
    ///
    /// Using this endpoint to verify App token
    ///
    /// - Since: 2.0.0
    /// - Version: 3.3.1
    /// # Last Update
    ///   2021/8/17
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/apps/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: App token
    /// - Returns: `AnyPublisher` contains `Application` nested in the response
    public static func verifyCredentials(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Application> {
        let request = Mastodon.API.request(
            url: verifyCredentialsEndpointURL(domain: domain),
            method: .GET,
            query: nil,
            authorization: authorization
        )
        
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Application.self, from: data, response: response)
        
        return Mastodon.Response.Content(value: value, response: response)
    }

}
