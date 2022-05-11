//
//  AppSecret.swift
//  
//
//  Created by MainasuK on 2021/11/22.
//

import Foundation
import CryptoKit
import TwitterSDK

public class AppSecret {
    
    public typealias Secret = String

    public let secret: Secret
    public let oauthSecret: OAuthSecret

    public init(
        secret: Secret,
        oauthSecret: AppSecret.OAuthSecret
    ) {
        self.secret = secret
        self.oauthSecret = oauthSecret
    }

}

extension AppSecret {
    public struct OAuthSecret {
        public let consumerKey: String
        public let consumerKeySecret: String
        public let clientID: String
        public let hostPublicKey: Curve25519.KeyAgreement.PublicKey?
        public let oauthEndpoint: String
        public let oauth2Endpoint: String
        
        public init(
            consumerKey: String,
            consumerKeySecret: String,
            clientID: String,
            hostPublicKey: Curve25519.KeyAgreement.PublicKey?,
            oauthEndpoint: String,
            oauth2Endpoint: String
        ) {
            self.consumerKey = consumerKey
            self.consumerKeySecret = consumerKeySecret
            self.clientID = clientID
            self.hostPublicKey = hostPublicKey
            self.oauthEndpoint = oauthEndpoint
            self.oauth2Endpoint = oauth2Endpoint
        }
    }
}

// MARK: - TwitterAuthorizationContextProvider
extension AppSecret: TwitterAuthorizationContextProvider {
    public var oauth: Twitter.AuthorizationContext.OAuth.Context {
        let endpoint = oauthSecret.oauthEndpoint
        switch endpoint {
        case "oob":
            return .standard(.init(
                    consumerKey: oauthSecret.consumerKey,
                    consumerKeySecret: oauthSecret.consumerKeySecret
                )
            )
            
        default:
            return .relay(.init(
                    consumerKey: oauthSecret.consumerKey,
                    hostPublicKey: oauthSecret.hostPublicKey!,
                    oauthEndpoint: oauthSecret.oauthEndpoint
                )
            )
        }
    }
    
    public var oauth2: Twitter.AuthorizationContext.OAuth2.Context {
        let endpoint = oauthSecret.oauth2Endpoint
        switch endpoint {
        default:
            return .relay(.init(
                clientID: oauthSecret.clientID,
                consumerKey: oauthSecret.consumerKey,
                consumerKeySecret: oauthSecret.consumerKeySecret,
                endpoint: URL(string: oauthSecret.oauth2Endpoint)!,
                hostPublicKey: oauthSecret.hostPublicKey!
            ))
        }
    }
}

extension AppSecret {
    public static func authenticationWrapKey(secret: AppSecret.Secret, nonce: String, field: String) throws -> SymmetricKey {
        let keyMaterial: SymmetricKey = {
            var sha256 = SHA256()
            sha256.update(data: Data(secret.utf8))
            let digest = sha256.finalize()
            return SymmetricKey(data: digest)
        }()
        let salt: Data = Data(nonce.utf8) + Data(field.utf8)
        
        let info = Data("\(field) database key".utf8)
        let outputByteCount = 32
        let wrapKey = CryptoKit.HKDF<SHA256>.deriveKey(inputKeyMaterial: keyMaterial, salt: salt, info: info, outputByteCount: outputByteCount)
        
        return wrapKey
    }
}
