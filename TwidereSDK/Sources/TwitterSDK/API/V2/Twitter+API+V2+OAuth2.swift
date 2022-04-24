//
//  Twitter+API+V2+OAuth2.swift
//  
//
//  Created by MainasuK on 2022-4-21.
//

import os.log
import Foundation
import CryptoKit

extension Twitter.API.V2 {
    public enum OAuth2 { }
}

extension Twitter.API.V2.OAuth2 {
    
    static let logger = Logger(subsystem: "Twitter.API.V2.OAuth2", category: "API")
    static let authorizeEndpointURL = URL(string: "https://twitter.com/i/oauth2/authorize")!
}

extension Twitter.API.V2.OAuth2 {
    
    public static func authorizeURL(
        endpoint: URL,
        clientID: String,
        challenge: String,
        state: String
    ) -> URL {
        let redirectURI = endpoint
            .appendingPathComponent("oauth2")
            .appendingPathComponent("callback")
        var components = URLComponents(string: authorizeEndpointURL.absoluteString)!
        components.percentEncodedQueryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID.urlEncoded),
            URLQueryItem(name: "scope", value: "tweet.read users.read follows.read follows.write offline.access bookmark.read".urlEncoded),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "redirect_uri", value: redirectURI.absoluteString.urlEncoded),
        ]
        let authorizeURL = components.url!
        return authorizeURL
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
