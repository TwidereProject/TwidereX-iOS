//
//  AppSecret.swift
//  
//
//  Created by MainasuK on 2021/11/22.
//

import Foundation
import CryptoKit
import TwitterSDK
import MastodonSDK
import KeychainAccess
import ArkanaKeys

public class AppSecret {

    public typealias Secret = String

    // keychain
    public static let keychain = Keychain(service: "com.twidere.TwidereX.keychain", accessGroup: AppCommon.groupID)
    
    // notification key names
    static let mastodonNotificationPrivateKeyName = "notification-private-key-base64"
    static let mastodonNotificationAuthName = "notification-auth-base64"
    
    public let secret: Secret
    public let oauthSecret: OAuthSecret
    
    // Mastodon notification keys
    public let mastodonNotificationRelayEndpoint: String
    public var mastodonNotificationPrivateKey: P256.KeyAgreement.PrivateKey {
        AppSecret.createOrFetchNotificationPrivateKey()
    }
    public var mastodonNotificationPublicKey: P256.KeyAgreement.PublicKey {
        mastodonNotificationPrivateKey.publicKey
    }
    public var mastodonNotificationAuth: Data {
        AppSecret.createOrFetchNotificationAuth()
    }

    public init(
        secret: Secret,
        oauthSecret: AppSecret.OAuthSecret,
        mastodonNotificationRelayEndpoint: String
    ) {
        self.secret = secret
        self.oauthSecret = oauthSecret
        self.mastodonNotificationRelayEndpoint = mastodonNotificationRelayEndpoint
    }
    
    public static func register() {
        _ = AppSecret.createOrFetchNotificationPrivateKey()
        _ = AppSecret.createOrFetchNotificationAuth()
    }

}

extension AppSecret {
    
    public convenience init(
        oauthSecret: OAuthSecret,
        mastodonNotificationEndpoint: String
    ) {
        self.init(
            secret: Keys.Global().appSecret,
            oauthSecret: oauthSecret,
            mastodonNotificationRelayEndpoint: mastodonNotificationEndpoint
        )
    }
    
    public static let `default`: AppSecret = {
        let hostPublicKey: Curve25519.KeyAgreement.PublicKey? = {
            let keyString = Keys.Global().hostKeyPublic
            guard let keyData = Data(base64Encoded: keyString),
                  let key = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: keyData) else {
                return nil
            }
            
            return key
        }()
        
        #if DEBUG
        let keys = Keys.Debug()
        #else
        let keys = Keys.Release()
        #endif
        
        let oauthSecret = AppSecret.OAuthSecret(
            consumerKey: keys.consumerKey,
            consumerKeySecret: keys.consumerKeySecret,
            clientID: keys.clientID,
            hostPublicKey: hostPublicKey,
            oauthEndpoint: keys.oauthEndpoint,
            oauth2Endpoint: keys.oauth2Endpoint
        )
        let appSecret = AppSecret(
            oauthSecret: oauthSecret,
            mastodonNotificationEndpoint: keys.mastodonNotificationEndpoint
        )
        return appSecret
    }()
    
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

extension AppSecret {
    
    private static func createOrFetchNotificationPrivateKey() -> P256.KeyAgreement.PrivateKey {
        if let encoded = AppSecret.keychain[AppSecret.mastodonNotificationPrivateKeyName],
           let data = Data(base64Encoded: encoded) {
            do {
                let privateKey = try P256.KeyAgreement.PrivateKey(rawRepresentation: data)
                return privateKey
            } catch {
                assertionFailure()
                return AppSecret.resetNotificationPrivateKey()
            }
        } else {
            return AppSecret.resetNotificationPrivateKey()
        }
    }
    
    private static func resetNotificationPrivateKey() -> P256.KeyAgreement.PrivateKey {
        let privateKey = P256.KeyAgreement.PrivateKey()
        keychain[AppSecret.mastodonNotificationPrivateKeyName] = privateKey.rawRepresentation.base64EncodedString()
        return privateKey
    }
    
}

extension AppSecret {
    
    private static func createOrFetchNotificationAuth() -> Data {
        if let encoded = keychain[AppSecret.mastodonNotificationAuthName],
           let data = Data(base64Encoded: encoded) {
            return data
        } else {
            return AppSecret.resetNotificationAuth()
        }
    }
    
    private static func resetNotificationAuth() -> Data {
        let auth = AppSecret.createRandomAuthBytes()
        keychain[AppSecret.mastodonNotificationAuthName] = auth.base64EncodedString()
        return auth
    }
    
    private static func createRandomAuthBytes() -> Data {
        let byteCount = 16
        var bytes = Data(count: byteCount)
        _ = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, byteCount, $0.baseAddress!) }
        return bytes
    }
    
}
