//
//  TwitterAuthentication.swift
//  
//
//  Created by MainasuK on 2021/11/22.
//

import Foundation
import CryptoKit
import CoreDataStack
import TwidereCommon
import TwitterSDK

extension AuthenticationIndex {
    
    public var user: UserObject? {
        switch platform {
        case .twitter:
            guard let user = twitterAuthentication?.user else { return nil }
            return .twitter(object: user)
        case .mastodon:
            guard let user = mastodonAuthentication?.user else { return nil }
            return .mastodon(object: user)
        case .none:
            return nil
        }
    }
}

extension TwitterAuthentication.Property {
    
    public func sealing(secret: AppSecret.Secret) throws -> TwitterAuthentication.Property {
        let nonce = UUID().uuidString

        let consumerKey = try TwitterAuthentication.Property.sealFieldValue(secret: secret, nonce: nonce, field: "consumerKey", value: self.consumerKey)
        let consumerSecret = try TwitterAuthentication.Property.sealFieldValue(secret: secret, nonce: nonce, field: "consumerSecret", value: self.consumerSecret)
        let accessToken = try TwitterAuthentication.Property.sealFieldValue(secret: secret, nonce: nonce, field: "accessToken", value: self.accessToken)
        let accessTokenSecret = try TwitterAuthentication.Property.sealFieldValue(secret: secret, nonce: nonce, field: "accessTokenSecret", value: self.accessTokenSecret)
        let bearerAccessToken = try TwitterAuthentication.Property.sealFieldValue(secret: secret, nonce: nonce, field: "bearerAccessToken", value: self.bearerAccessToken)
        let bearerRefreshToken = try TwitterAuthentication.Property.sealFieldValue(secret: secret, nonce: nonce, field: "bearerRefreshToken", value: self.bearerRefreshToken)
        
        let property = TwitterAuthentication.Property(
            userID: userID,
            screenName: screenName,
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            accessToken: accessToken,
            accessTokenSecret: accessTokenSecret,
            nonce: nonce,
            bearerAccessToken: bearerAccessToken,
            bearerRefreshToken: bearerRefreshToken,
            updatedAt: Date()
        )
        
        return property
    }
    
    private static func sealFieldValue(secret: String, nonce: String, field: String, value: String) throws -> String {
        let wrapKey = try AppSecret.authenticationWrapKey(secret: secret, nonce: nonce, field: field)
        let sealedBox = try ChaChaPoly.seal(Data(value.utf8), using: wrapKey)
        return sealedBox.combined.base64EncodedString()
    }
    
}

extension TwitterAuthentication {
    
    public func authorization(secret: AppSecret.Secret) throws -> Twitter.API.OAuth.Authorization {
        guard !self.nonce.isEmpty else {
            return Twitter.API.OAuth.Authorization(
                consumerKey: self.consumerKey,
                consumerSecret: self.consumerSecret,
                accessToken: self.accessToken,
                accessTokenSecret: self.accessTokenSecret
            )
        }
        let nonce = self.nonce
        
        let consumerKey = try TwitterAuthentication.openFieldValue(secret: secret, nonce: nonce, field: "consumerKey", ciphertext: self.consumerKey)
        let consumerSecret = try TwitterAuthentication.openFieldValue(secret: secret, nonce: nonce, field: "consumerSecret", ciphertext: self.consumerSecret)
        let accessToken = try TwitterAuthentication.openFieldValue(secret: secret, nonce: nonce, field: "accessToken", ciphertext: self.accessToken)
        let accessTokenSecret = try TwitterAuthentication.openFieldValue(secret: secret, nonce: nonce, field: "accessTokenSecret", ciphertext: self.accessTokenSecret)
        
        return Twitter.API.OAuth.Authorization(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            accessToken: accessToken,
            accessTokenSecret: accessTokenSecret
        )
    }
    
    public func authorizationV2(secret: AppSecret.Secret) throws -> Twitter.API.V2.OAuth2.Authorization {
        let accessToken = try TwitterAuthentication.openFieldValue(secret: secret, nonce: nonce, field: "bearerAccessToken", ciphertext: self.bearerAccessToken)
        let refreshToken = try TwitterAuthentication.openFieldValue(secret: secret, nonce: nonce, field: "bearerRefreshToken", ciphertext: self.bearerRefreshToken)
        
        return Twitter.API.V2.OAuth2.Authorization(
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }
    
    private static func openFieldValue(secret: AppSecret.Secret, nonce: String, field: String, ciphertext: String) throws -> String {
        let wrapKey = try AppSecret.authenticationWrapKey(secret: secret, nonce: nonce, field: field)
        let sealedBox = try ChaChaPoly.SealedBox(combined: Data(base64Encoded: ciphertext) ?? Data())
        let valueData = try ChaChaPoly.open(sealedBox, using: wrapKey)
        return String(data: valueData, encoding: .utf8) ?? ""
    }
    
}
