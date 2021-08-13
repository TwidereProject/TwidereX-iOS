//
//  AppSecret.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-21.
//

import Foundation
import CryptoKit
import TwitterSDK
import Keys

public class AppSecret {
    
    public let appSecret: String
    public let oauthSecret: OAuthSecret

    public static let `default`: AppSecret = {
        let keys = TwidereXKeys()
        let hostPublicKey: Curve25519.KeyAgreement.PublicKey? = {
            let keyString = keys.host_key_public
            guard let keyData = Data(base64Encoded: keyString),
                  let key = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: keyData) else {
                return nil
            }
            
            return key
        }()
        #if DEBUG
        let oauthEndpoint = keys.oauth_endpoint_debug
        #else
        let oauthEndpoint = keys.oauth_endpoint
        #endif
        
        let oauthSecret = AppSecret.OAuthSecret(
            consumerKey: keys.consumer_key,
            consumerKeySecret: keys.consumer_key_secret,
            hostPublicKey: hostPublicKey,
            oauthEndpoint: oauthEndpoint
        )
        let appSecret = AppSecret(oauthSecret: oauthSecret)
        return appSecret
    }()
    
    public init(oauthSecret: OAuthSecret) {
        let keys = TwidereXKeys()
        self.appSecret = keys.app_secret
        self.oauthSecret = oauthSecret
    }
    
}

extension AppSecret {
    public struct OAuthSecret {
        public let consumerKey: String
        public let consumerKeySecret: String
        public let hostPublicKey: Curve25519.KeyAgreement.PublicKey?
        public let oauthEndpoint: String
        
        public init(
            consumerKey: String,
            consumerKeySecret: String,
            hostPublicKey: Curve25519.KeyAgreement.PublicKey?,
            oauthEndpoint: String
        ) {
            self.consumerKey = consumerKey
            self.consumerKeySecret = consumerKeySecret
            self.hostPublicKey = hostPublicKey
            self.oauthEndpoint = oauthEndpoint
        }
    }
}

extension AppSecret: TwitterOAuthExchangeProvider {
    public func oauthExchange() -> Twitter.API.OAuth.OAuthExchange {
        let oauthEndpoint = oauthSecret.oauthEndpoint
        switch oauthEndpoint {
        case "oob":
            return .pin(exchange: .init(
                consumerKey: oauthSecret.consumerKey,
                consumerKeySecret: oauthSecret.consumerKeySecret
            ))
        default:
            return .custom(exchange: .init(
                consumerKey: oauthSecret.consumerKey,
                hostPublicKey: oauthSecret.hostPublicKey!,
                oauthEndpoint: oauthSecret.oauthEndpoint
            ))
        }
    }
}

extension AppSecret {
    public static func authenticationWrapKey(appSecret: String, nonce: String, field: String) throws -> SymmetricKey {
        let keyMaterial: SymmetricKey = {
            var sha256 = SHA256()
            sha256.update(data: Data(appSecret.utf8))
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
