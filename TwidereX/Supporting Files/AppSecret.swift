//
//  AppSecret.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-21.
//

import Foundation
import CryptoKit
import CryptoSwift
import TwitterAPI
import Keys

class AppSecret {
    
    let appSecret: String
    let oauthSecret: OAuthSecret

    static let `default`: AppSecret = {
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
    
    init(oauthSecret: OAuthSecret) {
        let keys = TwidereXKeys()
        self.appSecret = keys.app_secret
        self.oauthSecret = oauthSecret
    }
    
}

extension AppSecret {
    struct OAuthSecret {
        let consumerKey: String
        let consumerKeySecret: String
        let hostPublicKey: Curve25519.KeyAgreement.PublicKey?
        let oauthEndpoint: String
        
        init(
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

extension AppSecret: OAuthExchangeProvider {
    func oauthExcahnge() -> Twitter.API.OAuth.OAuthExchange {
        let oauthEndpoint = oauthSecret.oauthEndpoint
        switch oauthEndpoint {
        case "oob":
            return .pin(
                consumerKey: oauthSecret.consumerKey,
                consumerKeySecret: oauthSecret.consumerKeySecret
            )
        default:
            return .custom(
                consumerKey: oauthSecret.consumerKey,
                hostPublicKey: oauthSecret.hostPublicKey!,
                oauthEndpoint: oauthSecret.oauthEndpoint
            )
        }
    }
}

extension AppSecret {
    static func authenticationWrapKey(appSecret: String, nonce: String, field: String) throws -> SymmetricKey {
        let keyMaterial: SymmetricKey = {
            var sha256 = SHA256()
            sha256.update(data: Data(appSecret.utf8))
            let digest = sha256.finalize()
            return SymmetricKey(data: digest)
        }()
        let salt: Data = Data(nonce.utf8) + Data(field.utf8)
        
        let wrapKey: SymmetricKey
        let info = Data("\(field) database key".utf8)
        let outputByteCount = 32
        if #available(iOS 14.0, *) {
            wrapKey = CryptoKit.HKDF<SHA256>.deriveKey(inputKeyMaterial: keyMaterial, salt: salt, info: info, outputByteCount: outputByteCount)
        } else {
            let password = keyMaterial.withUnsafeBytes { Data($0) }
            let wrapKeyData = try CryptoSwift.HKDF(password: password.bytes, salt: salt.bytes, info: info.bytes, keyLength: outputByteCount, variant: .sha256).calculate()
            wrapKey = SymmetricKey(data: Data(wrapKeyData))
        }
        
        return wrapKey
    }
}
