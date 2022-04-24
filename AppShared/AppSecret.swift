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
            secret: keys.app_secret,
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
        let oauth2Endpoint = keys.oauth2_endpoint_debug
        let clientID = keys.client_id_debug
        #else
        let oauthEndpoint = keys.oauth_endpoint
        let oauth2Endpoint = keys.oauth2_endpoint
        let clientID = keys.client_id
        #endif
        
        let oauthSecret = AppSecret.OAuthSecret(
            consumerKey: keys.consumer_key,
            consumerKeySecret: keys.consumer_key_secret,
            clientID: clientID,
            hostPublicKey: hostPublicKey,
            oauthEndpoint: oauthEndpoint,
            oauth2Endpoint: oauth2Endpoint
        )
        let appSecret = AppSecret(oauthSecret: oauthSecret)
        return appSecret
    }()
    
}

