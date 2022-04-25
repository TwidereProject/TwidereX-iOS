//
//  Twitter+API+V2+OAuth2+Authorize.swift
//  
//
//  Created by MainasuK on 2022-4-24.
//

import os.log
import Foundation
import CryptoKit

extension Twitter.API.V2.OAuth2 {
    public enum Authorize {
        public enum Standard { }
        public enum Relay { }
    }
}

extension Twitter.API.V2.OAuth2.Authorize.Standard {
    
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

extension Twitter.API.V2.OAuth2.Authorize.Relay {
    
    static let logger = Logger(subsystem: "Twitter.API.V2.OAuth2.Authorize.Relay", category: "API")
    
    static let callbackURL = URL(string: "twidere://authentication/oauth2/callback")!
    
    public static func authorize(
        session: URLSession,
        query: Query
    ) async throws -> Response {

        let clientEphemeralPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        let clientEphemeralPublicKey = clientEphemeralPrivateKey.publicKey
        do {
            let sharedSecret = try clientEphemeralPrivateKey.sharedSecretFromKeyAgreement(with: query.hostPublicKey)
            let salt = clientEphemeralPublicKey.rawRepresentation + sharedSecret.withUnsafeBytes { Data($0) }
            let wrapKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: salt, sharedInfo: Data("oauth2".utf8), outputByteCount: 32)
            let box = Box(
                clientID: query.clientID,
                consumerKey: query.consumerKey,
                consumerKeySecret: query.consumerKeySecret
            )
            let boxData = try JSONEncoder().encode(box)
            let sealedBox = try ChaChaPoly.seal(boxData, using: wrapKey)
            let payload = Payload(
                exchangePublicKey: clientEphemeralPublicKey.rawRepresentation.base64EncodedString(),
                box: sealedBox.combined.base64EncodedString()
            )
            var request = URLRequest(
                url: query.endpoint.appendingPathComponent("/oauth2"),
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                timeoutInterval: Twitter.API.timeoutInterval
            )
            request.httpMethod = "POST"
            request.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(payload)
            
            let (data, _) = try await session.data(for: request, delegate: nil)
            let content = try JSONDecoder().decode(Response.Content.self, from: data)
            os_log("%{public}s[%{public}ld], %{public}s: request token response: %s", ((#file as NSString).lastPathComponent), #line, #function, String(describing: content))
            let response = Response(
                content: content,
                append: .init(clientExchangePrivateKey: clientEphemeralPrivateKey)
            )
            return response
        } catch {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): error: \(error.localizedDescription)")
            throw error
        }
    }   // end func
    
    public struct Query {
        public let clientID: String
        public let consumerKey: String
        public let consumerKeySecret: String?
        public let endpoint: URL
        public let hostPublicKey: Curve25519.KeyAgreement.PublicKey
                
        public init(
            clientID: String,
            consumerKey: String,
            consumerKeySecret: String?,
            endpoint: URL,
            hostPublicKey: Curve25519.KeyAgreement.PublicKey
        ) {
            self.clientID = clientID
            self.consumerKey = consumerKey
            self.consumerKeySecret = consumerKeySecret
            self.endpoint = endpoint
            self.hostPublicKey = hostPublicKey
        }
    }
    
    public struct Response {
        public let content: Content
        public let append: Append
        
        public struct Content: Codable {
            public let challenge: String
            public let state: String
            
            public init(
                challenge: String,
                state: String
            ) {
                self.challenge = challenge
                self.state = state
            }
        }
        
        public struct Append {
            public let clientExchangePrivateKey: Curve25519.KeyAgreement.PrivateKey
        }
    }
    
    
    public struct Payload: Codable {
        /// client ephemeral public key`
        public let exchangePublicKey: String
        
        /// sealed Box
        public let box: String
        
        enum CodingKeys: String, CodingKey, CaseIterable {
            case exchangePublicKey = "exchange_public_key"
            case box
        }
    }
    
    public struct Box: Codable {
        public let clientID: String
        public let consumerKey: String
        public let consumerKeySecret: String?
        
        enum CodingKeys: String, CodingKey, CaseIterable {
            case clientID = "client_id"
            case consumerKey = "consumer_key"
            case consumerKeySecret = "consumer_key_secret"
        }
    }

    public struct OAuthCallback: Codable {
        let exchangePublicKey: String
        let authenticationBox: String
        
        enum CodingKeys: String, CodingKey, CaseIterable {
            case exchangePublicKey = "exchange_public_key"
            case authenticationBox = "authentication_box"
        }
        
        public init?(callbackURL url: URL) {
            guard let urlComponents = URLComponents(string: url.absoluteString) else { return nil }
            guard let queryItems = urlComponents.queryItems,
                  let exchangePublicKey = queryItems.first(where: { $0.name == CodingKeys.exchangePublicKey.rawValue })?.value,
                  let authenticationBox = queryItems.first(where: { $0.name == CodingKeys.authenticationBox.rawValue })?.value else
            {
                return nil
            }
            self.exchangePublicKey = exchangePublicKey
            self.authenticationBox = authenticationBox
        }
        
        public func authentication(privateKey: Curve25519.KeyAgreement.PrivateKey) throws -> Authentication {
            do {
                guard let exchangePublicKeyData = Data(base64Encoded: exchangePublicKey),
                      let sealedBoxData = Data(base64Encoded: authenticationBox) else {
                    throw Twitter.API.Error.InternalError(message: "invalid callback")
                }
                let exchangePublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: exchangePublicKeyData)
                let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: exchangePublicKey)
                let salt = exchangePublicKey.rawRepresentation + sharedSecret.withUnsafeBytes { Data($0) }
                let wrapKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: salt, sharedInfo: Data("authentication exchange".utf8), outputByteCount: 32)
                let sealedBox = try ChaChaPoly.SealedBox(combined: sealedBoxData)
                
                let authenticationData = try ChaChaPoly.open(sealedBox, using: wrapKey)
                let authentication = try JSONDecoder().decode(Authentication.self, from: authenticationData)
                return authentication
                
            } catch {
                if let error = error as? Twitter.API.Error.ResponseError {
                    throw error
                } else {
                    throw Twitter.API.Error.InternalError(message: error.localizedDescription)
                }
            }
        }
    }
    
    public struct Authentication: Codable {
        // oauth1.0a
        public let oauthConsumerKey: String
        public let oauthConsumerSecret: String
        public let oauthAccessToken: String
        public let oauthAccessTokenSecret: String
        public let userID: String
        public let screenName: String
        // oauth2.0
        public let oauth2AccessToken: String
        public let oauth2RefreshToken: String
        
        enum CodingKeys: String, CodingKey {
            case oauthConsumerKey = "oauth_consumer_key"
            case oauthConsumerSecret = "oauth_consumer_secret"
            case oauthAccessToken = "oauth_access_token"
            case oauthAccessTokenSecret = "oauth_access_token_secret"
            case userID = "user_id"
            case screenName = "screen_name"
            case oauth2AccessToken = "oauth2_access_token"
            case oauth2RefreshToken = "oauth2_refresh_token"
        }
        
        public init(
            oauthConsumerKey: String,
            oauthConsumerSecret: String,
            oauthAccessToken: String,
            oauthAccessTokenSecret: String,
            userID: String,
            screenName: String,
            oauth2AccessToken: String,
            oauth2RefreshToken: String
        ) {
            self.oauthConsumerKey = oauthConsumerKey
            self.oauthConsumerSecret = oauthConsumerSecret
            self.oauthAccessToken = oauthAccessToken
            self.oauthAccessTokenSecret = oauthAccessTokenSecret
            self.userID = userID
            self.screenName = screenName
            self.oauth2AccessToken = oauth2AccessToken
            self.oauth2RefreshToken = oauth2RefreshToken
        }
    }
    
}
