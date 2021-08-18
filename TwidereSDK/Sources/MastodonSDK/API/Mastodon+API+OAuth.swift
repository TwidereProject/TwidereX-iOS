//
//  Mastodon+API+OAuth.swift
//  Mastodon+API+OAuth
//
//  Created by MainasuK Cirno on 2021/8/17.
//

import Foundation

extension Mastodon.API.OAuth {
    
    public static let authorizationField = "Authorization"
    
    public struct Authorization {
        public let accessToken: String
        
        public init(accessToken: String) {
            self.accessToken = accessToken
        }
    }
    
}

extension Mastodon.API.OAuth {
    
    static func authorizeEndpointURL(domain: String) -> URL {
        return Mastodon.API.oauthEndpointURL(domain: domain).appendingPathComponent("authorize")
    }
    
    /// Construct user authorize endpoint URL
    ///
    /// This method construct a URL for user authorize
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.1
    /// # Last Update
    ///   2021/8/17
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/apps/oauth/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `AuthorizeQuery`
    public static func authorizeURL(
        domain: String,
        query: AuthorizeQuery
    ) -> URL {
        let request = Mastodon.API.request(
            url: authorizeEndpointURL(domain: domain),
            method: .GET,
            query: query,
            authorization: nil
        )
        let url = request.url!
        return url
    }
    
    public struct AuthorizeQuery: Codable, Query {
        
        public let forceLogin: String?
        public let responseType: String
        public let clientID: String
        public let redirectURI: String
        public let scope: String?
        
        public init(
            forceLogin: String? = nil,
            responseType: String = "code",
            clientID: String,
            redirectURI: String,
            scope: String? = "read write follow push"
        ) {
            self.forceLogin = forceLogin
            self.responseType = responseType
            self.clientID = clientID
            self.redirectURI = redirectURI
            self.scope = scope
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            forceLogin.flatMap { items.append(URLQueryItem(name: "force_login", value: $0)) }
            items.append(URLQueryItem(name: "response_type", value: responseType))
            items.append(URLQueryItem(name: "client_id", value: clientID))
            items.append(URLQueryItem(name: "redirect_uri", value: redirectURI))
            scope.flatMap { items.append(URLQueryItem(name: "scope", value: $0)) }
            guard !items.isEmpty else { return nil }
            return items
        }
        
    }
    
}
    
extension Mastodon.API.OAuth {
    
    static func accessTokenEndpointURL(domain: String) -> URL {
        return Mastodon.API.oauthEndpointURL(domain: domain).appendingPathComponent("token")
    }
    
    /// Obtain User Access Token
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.1
    /// # Last Update
    ///   2021/8/17
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/apps/oauth/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `AccessTokenQuery`
    /// - Returns: `AnyPublisher` contains `Token` nested in the response
    public static func accessToken(
        session: URLSession,
        domain: String,
        query: AccessTokenQuery
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Token> {
        let request = Mastodon.API.request(
            url: accessTokenEndpointURL(domain: domain),
            method: .POST,
            query: query,
            authorization: nil
        )
        
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Token.self, from: data, response: response)
        
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public struct AccessTokenQuery: Codable, Query {
        
        public enum GrantType: String, Codable {
            case authorizationCode = "authorization_code"
            case clientCredentials = "client_credentials"
        }
        
        public let clientID: String
        public let clientSecret: String
        public let redirectURI: String
        public let scope: String?
        public let code: String?
        public let grantType: GrantType
        
        enum CodingKeys: String, CodingKey {
            case clientID = "client_id"
            case clientSecret = "client_secret"
            case redirectURI = "redirect_uri"
            case scope
            case code
            case grantType = "grant_type"
        }
        
        public init(
            clientID: String,
            clientSecret: String,
            redirectURI: String,
            scope: String? = "read write follow push",
            code: String?,
            grantType: GrantType
        ) {
            self.clientID = clientID
            self.clientSecret = clientSecret
            self.redirectURI = redirectURI
            self.scope = scope
            self.code = code
            self.grantType = grantType
        }
        
        public var queryItems: [URLQueryItem]? { nil }
    }
    
}


extension Mastodon.API.OAuth {

    static func revokeTokenEndpointURL(domain: String) -> URL {
        return Mastodon.API.oauthEndpointURL(domain: domain).appendingPathComponent("revoke")
    }
    
    /// Revoke User Access Token
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.1
    /// # Last Update
    ///   2021/8/17
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/apps/oauth/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `RevokeTokenQuery`
    /// - Returns: `AnyPublisher` contains `Token` nested in the response
    public static func revokeToken(
        session: URLSession,
        domain: String,
        query: RevokeTokenQuery
    ) async throws {
        let request = Mastodon.API.request(
            url: revokeTokenEndpointURL(domain: domain),
            method: .POST,
            query: query,
            authorization: nil
        )
        
        let (data, response) = try await session.data(for: request, delegate: nil)
        _ = try Mastodon.API.decode(type: String.self, from: data, response: response)
    }
    
    public struct RevokeTokenQuery: Codable, Query {
        public let clientID: String
        public let clientSecret: String
        public let token: String
        
        enum CodingKeys: String, CodingKey {
            case clientID = "client_id"
            case clientSecret = "client_secret"
            case token
        }
        
        var queryItems: [URLQueryItem]? { nil }
    }
    
}
