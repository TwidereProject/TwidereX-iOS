//
//  TwitterAuthentication.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-23.
//

import Foundation
import CryptoKit
import CoreDataStack
import AppShared
import TwitterSDK

extension TwitterAuthentication.Property {
    
    func seal(appSecret: AppSecret) throws -> TwitterAuthentication.Property {
        let nonce = UUID().uuidString
        let appSecret = appSecret.appSecret

        let consumerKey = try TwitterAuthentication.Property.sealFieldValue(appSecret: appSecret, nonce: nonce, field: "consumerKey", value: self.consumerKey)
        let consumerSecret = try TwitterAuthentication.Property.sealFieldValue(appSecret: appSecret, nonce: nonce, field: "consumerSecret", value: self.consumerSecret)
        let accessToken = try TwitterAuthentication.Property.sealFieldValue(appSecret: appSecret, nonce: nonce, field: "accessToken", value: self.accessToken)
        let accessTokenSecret = try TwitterAuthentication.Property.sealFieldValue(appSecret: appSecret, nonce: nonce, field: "accessTokenSecret", value: self.accessTokenSecret)
        let property = TwitterAuthentication.Property(
            userID: self.userID,
            screenName: self.screenName,
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            accessToken: accessToken,
            accessTokenSecret: accessTokenSecret,
            nonce: nonce
        )
        return property
    }
    
    private static func sealFieldValue(appSecret: String, nonce: String, field: String, value: String) throws -> String {
        let wrapKey = try AppSecret.authenticationWrapKey(appSecret: appSecret, nonce: nonce, field: field)
        let sealedBox = try ChaChaPoly.seal(Data(value.utf8), using: wrapKey)
        return sealedBox.combined.base64EncodedString()
    }
    
}

extension TwitterAuthentication {
    
    func authorization(appSecret: AppSecret) throws -> Twitter.API.OAuth.Authorization {
        guard !self.nonce.isEmpty else {
            return Twitter.API.OAuth.Authorization(
                consumerKey: self.consumerKey,
                consumerSecret: self.consumerSecret,
                accessToken: self.accessToken,
                accessTokenSecret: self.accessTokenSecret
            )
        }
        let appSecret = appSecret.appSecret
        let nonce = self.nonce
        
        let consumerKey = try TwitterAuthentication.openFieldValue(appSecret: appSecret, nonce: nonce, field: "consumerKey", ciphertext: self.consumerKey)
        let consumerSecret = try TwitterAuthentication.openFieldValue(appSecret: appSecret, nonce: nonce, field: "consumerSecret", ciphertext: self.consumerSecret)
        let accessToken = try TwitterAuthentication.openFieldValue(appSecret: appSecret, nonce: nonce, field: "accessToken", ciphertext: self.accessToken)
        let accessTokenSecret = try TwitterAuthentication.openFieldValue(appSecret: appSecret, nonce: nonce, field: "accessTokenSecret", ciphertext: self.accessTokenSecret)
        
        return Twitter.API.OAuth.Authorization(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            accessToken: accessToken,
            accessTokenSecret: accessTokenSecret
        )
    }
    
    private static func openFieldValue(appSecret: String, nonce: String, field: String, ciphertext: String) throws -> String {
        let wrapKey = try AppSecret.authenticationWrapKey(appSecret: appSecret, nonce: nonce, field: field)
        let sealedBox = try ChaChaPoly.SealedBox(combined: Data(base64Encoded: ciphertext) ?? Data())
        let valueData = try ChaChaPoly.open(sealedBox, using: wrapKey)
        return String(data: valueData, encoding: .utf8) ?? ""
    }
    
}
