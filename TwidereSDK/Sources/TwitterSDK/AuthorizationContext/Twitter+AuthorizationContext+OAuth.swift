//
//  Twitter+AuthorizationContext+OAuth.swift
//  
//
//  Created by MainasuK on 2022-4-24.
//

import Foundation
import CryptoKit

extension Twitter.AuthorizationContext {
    public enum OAuth {
        public enum Standard { }
        public enum Relay { }
    }
}

extension Twitter.AuthorizationContext.OAuth {
    public enum Context {
        case standard(Standard.Context)
        case relay(Relay.Context)
        
        public enum RequestTokenResponse {
            case standard(Twitter.API.OAuth.RequestToken.Standard.Response)
            case relay(Twitter.API.OAuth.RequestToken.Relay.Response)
        }
        
        public func requestToken(session: URLSession) async throws -> RequestTokenResponse {
            switch self {
            case .standard(let context):
                let response = try await Twitter.API.OAuth.RequestToken.Standard.requestToken(
                    session: session,
                    query: .init(
                        consumerKey: context.consumerKey,
                        consumerKeySecret: context.consumerKeySecret
                    )
                )
                return .standard(response)
            case .relay(let context):
                let response = try await Twitter.API.OAuth.RequestToken.Relay.requestToken(
                    session: session,
                    query: .init(
                        consumerKey: context.consumerKey,
                        hostPublicKey: context.hostPublicKey,
                        oauthEndpoint: context.oauthEndpoint
                    )
                )
                return .relay(response)
            }
        }
    }
}

extension Twitter.AuthorizationContext.OAuth.Standard {
    public struct Context {
        public let consumerKey: String
        public let consumerKeySecret: String
        
        public init(consumerKey: String, consumerKeySecret: String) {
            self.consumerKey = consumerKey
            self.consumerKeySecret = consumerKeySecret
        }
    }
}
    
extension Twitter.AuthorizationContext.OAuth.Relay {
    public struct Context {
        public let consumerKey: String
        public let hostPublicKey: Curve25519.KeyAgreement.PublicKey
        public let oauthEndpoint: String
        
        public init(consumerKey: String, hostPublicKey: Curve25519.KeyAgreement.PublicKey, oauthEndpoint: String) {
            self.consumerKey = consumerKey
            self.hostPublicKey = hostPublicKey
            self.oauthEndpoint = oauthEndpoint
        }
    }
}
    
