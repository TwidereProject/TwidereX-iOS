//
//  AppSecret.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-21.
//

import Foundation
import CryptoKit
import TwidereCommon
import Keys

extension AppSecret {
    
    public convenience init(oauthSecret: OAuthSecret) {
        let keys = TwidereXKeys()
        self.init(
            appSecret: keys.app_secret,
            oauthSecret: oauthSecret
        )
    }
    
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
    
}

