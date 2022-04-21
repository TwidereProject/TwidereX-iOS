//
//  Twitter+API+V2+OAuth2.swift
//  
//
//  Created by MainasuK on 2022-4-21.
//

import Foundation
import CryptoKit

extension Twitter.API.V2 {
    public enum OAuth2 { }
}

extension Twitter.API.V2.OAuth2 {
    
    static let authorizeEndpointURL = URL(string: "https://twitter.com/i/oauth2/authorize")!
    static let callbackURL = URL(string: "twidere://authentication/oauth2/callback")!
    
}

extension Twitter.API.V2.OAuth2 {
    public struct RequestTokenResponse {
        public let clientID: String
        public let verifier: String = Twitter.API.V2.OAuth2.createVerifier()
        public let callbackURL = URL(string: "twidere://authentication/oauth2/callback")!
    
        public init(
            clientID: String
        ) {
            self.clientID = clientID
        }
        
        public var challenge: Data {
            var sha256 = SHA256()
            sha256.update(data: Data(verifier.utf8))
            let digest = sha256.finalize()
            return Data(digest)
        }
        
        public var authorizeURL: URL {
            return Twitter.API.V2.OAuth2.authorizeURL(
                clientID: clientID,
                callbackURL: callbackURL,
                challenge: challenge
            )
        }
    }
}

extension Twitter.API.V2.OAuth2 {
    
    public static func createVerifier() -> String {
        let allowed = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-._~"
        return (0..<128).map { _ in
            String(allowed.randomElement()!)
        }.joined()
    }
    
    public static func authorizeURL(
        clientID: String,
        callbackURL: URL,
        challenge: Data
    ) -> URL {
        var components = URLComponents(string: authorizeEndpointURL.absoluteString)!
        let base64URLEncodedChallenge: String = {
            return challenge
                .base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }()
        components.percentEncodedQueryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID.urlEncoded),
            URLQueryItem(name: "scope", value: "tweet.read users.read follows.read follows.write offline.access bookmark.read".urlEncoded),
            URLQueryItem(name: "state", value: "state"),
            URLQueryItem(name: "code_challenge", value: base64URLEncodedChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "redirect_uri", value: callbackURL.absoluteString.urlEncoded),
        ]
        let authorizeURL = components.url!
        return authorizeURL
    }
    
    public struct OAuthCallback: Codable {

        public let state: String
        public let code: String

        enum CodingKeys: String, CodingKey, CaseIterable {
            case state
            case code
        }

        public init?(callbackURL url: URL) {
            guard let urlComponents = URLComponents(string: url.absoluteString) else { return nil }
            guard let queryItems = urlComponents.queryItems,
                  let state = queryItems.first(where: { $0.name == CodingKeys.state.rawValue })?.value,
                  let code = queryItems.first(where: { $0.name == CodingKeys.code.rawValue })?.value else
            {
                return nil
            }
            self.state = state
            self.code = code
        }

    }

}

extension Twitter.API.V2.OAuth2 {
    
    static let accessTokenURL = URL(string: "https://api.twitter.com/2/oauth2/token")!

    public static func accessToken(
        session: URLSession,
        query: AccessTokenQuery
    ) async throws -> AccessTokenResponse {
        var request = URLRequest(
            url: accessTokenURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: Twitter.API.timeoutInterval
        )
        request.httpMethod = "POST"
        if let contentType = query.contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        if let body = query.body {
            request.httpBody = body
        }

        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: AccessTokenResponse.self, from: data, response: response)
        return value
    }
    
    public struct AccessTokenQuery: Query {
        public let code: String
        public let grantType: String
        public let clientID: String
        public let redirectURI: String
        public let codeVerifier: String
        
        enum CodingKeys: String, CodingKey {
            case code
            case grantType = "grant_type"
            case clientID = "client_id"
            case redirectURI = "redirect_uri"
            case codeVerifier = "code_verifier"
        }
        
        public init(
            code: String,
            grantType: String = "authorization_code",
            clientID: String,
            redirectURI: String,
            codeVerifier: String
        ) {
            self.code = code
            self.grantType = grantType
            self.clientID = clientID
            self.redirectURI = redirectURI
            self.codeVerifier = codeVerifier
        }
        
        var queryItems: [URLQueryItem]? { nil }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { "application/x-www-form-urlencoded" }
        var body: Data? {
            let content = [
                CodingKeys.code.rawValue: code,
                CodingKeys.grantType.rawValue: grantType,
                CodingKeys.clientID.rawValue: clientID,
                CodingKeys.redirectURI.rawValue: redirectURI,
                CodingKeys.codeVerifier.rawValue: codeVerifier,
            ].urlEncodedQuery
            return content.data(using: .utf8)
        }
    }
        
    public struct AccessTokenResponse: Codable {
        public let tokenType: String
        public let expiresIn: Int
        public let scope: String
        public let accessToken: String
        public let refreshToken: String
        
        enum CodingKeys: String, CodingKey {
            case tokenType = "token_type"
            case expiresIn = "expires_in"
            case scope
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
        }
    }

}

extension Twitter.API.V2.OAuth2 {

    public struct Authorization: Hashable {
        public let accessToken: String
        public let refreshToken: String
        
        public init(
            accessToken: String,
            refreshToken: String
        ) {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
        }
        
        var authorizationHeader: String {
            return "Bearer \(accessToken)"
        }
    }
    
}
