//
//  Twitter+API+V2+OAuth2+AccessToken.swift
//  
//
//  Created by MainasuK on 2022-4-24.
//

import Foundation

extension Twitter.API.V2.OAuth2 {
    public enum AccessToken { }
}

extension Twitter.API.V2.OAuth2.AccessToken {
    
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
