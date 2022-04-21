//
//  Twitter+API+OAuth+RequestToken.swift
//  
//
//  Created by MainasuK on 2022-4-21.
//

import os.log
import Foundation
import CryptoKit


extension Twitter.API.OAuth {
    public enum RequestToken {
        public enum Standard { }
        public enum Relay { }
    }
}
    
extension Twitter.API.OAuth.RequestToken.Standard {
    
    public static func requestToken(
        session: URLSession,
        query: RequestTokenQuery
    ) async throws -> RequestTokenResponse {
        let request = requestTokenURLRequest(
            consumerKey: query.consumerKey,
            consumerKeySecret: query.consumerKeySecret
        )
        let (data, _) = try await session.data(for: request, delegate: nil)
        let templateURLString = Twitter.API.OAuth.requestTokenEndpointURL.absoluteString
        guard let body = String(data: data, encoding: .utf8),
              let components = URLComponents(string: templateURLString + "?" + body),
              let requestTokenResponse = RequestTokenResponse(queryItems: components.queryItems ?? [])
        else {
            throw Twitter.API.Error.InternalError(message: "process requestToken response fail")
        }
        return requestTokenResponse
    }
    
    public struct RequestTokenQuery {
        public let consumerKey: String
        public let consumerKeySecret: String
        
        public init(consumerKey: String, consumerKeySecret: String) {
            self.consumerKey = consumerKey
            self.consumerKeySecret = consumerKeySecret
        }
    }
    
    public struct RequestTokenResponse: Codable, CustomDebugStringConvertible {
        public let oauthToken: String
        public let oauthTokenSecret: String
        public let oauthCallbackConfirmed: Bool
        
        public enum CodingKeys: String, CodingKey {
            case oauthToken = "oauth_token"
            case oauthTokenSecret = "oauth_token_secret"
            case oauthCallbackConfirmed = "oauth_callback_confirmed"
        }
        
        init?(queryItems: [URLQueryItem]) {
            var _oauthToken: String?
            var _oauthTokenSecret: String?
            var _oauthCallbackConfirmed: Bool?
            for item in queryItems {
                switch item.name {
                case "oauth_token":                 _oauthToken = item.value
                case "oauth_token_secret":          _oauthTokenSecret = item.value
                case "oauth_callback_confirmed":    _oauthCallbackConfirmed = item.value == "true"
                default:                            continue
                }
            }
            
            guard let oauthToken = _oauthToken,
                  let oauthTokenSecret = _oauthTokenSecret,
                  let oauthCallbackConfirmed = _oauthCallbackConfirmed else {
                      return nil
                  }
            
            self.oauthToken = oauthToken
            self.oauthTokenSecret = oauthTokenSecret
            self.oauthCallbackConfirmed = oauthCallbackConfirmed
        }
        
        public var debugDescription: String {
            """
            - oauth_token: \(oauthToken)
            - oauth_token_secret: \(oauthTokenSecret)
            - oauth_callback_confirmed: \(oauthCallbackConfirmed)
            """
        }
    }
    
    static func requestTokenURLRequest(
        consumerKey: String,
        consumerKeySecret: String
    ) -> URLRequest {
        var components = URLComponents(string: Twitter.API.OAuth.requestTokenEndpointURL.absoluteString)!
        let queryItems = [URLQueryItem(name: "oauth_callback", value: "oob")]
        components.queryItems = queryItems
        let requestURL = components.url!
        var request = URLRequest(
            url: requestURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: Twitter.API.timeoutInterval
        )
        request.httpMethod = "POST"
        let authorizationHeader = Twitter.API.OAuth.authorizationHeader(
            requestURL: requestURL,
            requestFormQueryItems: queryItems,
            httpMethod: "POST",
            callbackURL: nil,
            consumerKey: consumerKey,
            consumerSecret: consumerKeySecret,
            oauthToken: nil,
            oauthTokenSecret: nil
        )
        request.setValue(authorizationHeader, forHTTPHeaderField: Twitter.API.OAuth.authorizationField)
        return request
    }
    
}

extension Twitter.API.OAuth.RequestToken.Relay {
    
    public static func requestToken(
        session: URLSession,
        query: RequestTokenQuery
    ) async throws -> RequestTokenResponse {
        let consumerKey = query.consumerKey
        let hostPublicKey = query.hostPublicKey
        let oauthEndpoint = query.oauthEndpoint
        os_log("%{public}s[%{public}ld], %{public}s: request token %s", ((#file as NSString).lastPathComponent), #line, #function, oauthEndpoint)
        
        let clientEphemeralPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        let clientEphemeralPublicKey = clientEphemeralPrivateKey.publicKey
        do {
            let sharedSecret = try clientEphemeralPrivateKey.sharedSecretFromKeyAgreement(with: hostPublicKey)
            let salt = clientEphemeralPublicKey.rawRepresentation + sharedSecret.withUnsafeBytes { Data($0) }
            let wrapKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: salt, sharedInfo: Data("request token exchange".utf8), outputByteCount: 32)
            let consumerKeyBox = try ChaChaPoly.seal(Data(consumerKey.utf8), using: wrapKey)
            let customRequestTokenPayload = CustomRequestTokenPayload(exchangePublicKey: clientEphemeralPublicKey, consumerKeyBox: consumerKeyBox)
            
            var request = URLRequest(url: URL(string: oauthEndpoint + "/oauth/request_token")!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Twitter.API.timeoutInterval)
            request.httpMethod = "POST"
            request.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(customRequestTokenPayload)
            
            let (data, _) = try await session.data(for: request, delegate: nil)
            os_log("%{public}s[%{public}ld], %{public}s: request token response data: %s", ((#file as NSString).lastPathComponent), #line, #function, String(data: data, encoding: .utf8) ?? "<nil>")
            let response = try JSONDecoder().decode(CustomRequestTokenResponse.self, from: data)
            os_log("%{public}s[%{public}ld], %{public}s: request token response: %s", ((#file as NSString).lastPathComponent), #line, #function, String(describing: response))
            
            guard let exchangePublicKeyData = Data(base64Encoded: response.exchangePublicKey),
                  let exchangePublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: exchangePublicKeyData),
                  let sharedSecret = try? clientEphemeralPrivateKey.sharedSecretFromKeyAgreement(with: exchangePublicKey),
                  let combinedData = Data(base64Encoded: response.requestTokenBox) else
                  {
                      throw Twitter.API.Error.InternalError(message: "invalid requestToken response")
                  }
            do {
                let salt = exchangePublicKey.rawRepresentation + sharedSecret.withUnsafeBytes { Data($0) }
                let wrapKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: salt, sharedInfo: Data("request token response exchange".utf8), outputByteCount: 32)
                let sealedBox = try ChaChaPoly.SealedBox(combined: combinedData)
                let requestTokenData = try ChaChaPoly.open(sealedBox, using: wrapKey)
                guard let requestToken = String(data: requestTokenData, encoding: .utf8) else {
                    throw Twitter.API.Error.InternalError(message: "invalid requestToken response")
                }
                let append = CustomRequestTokenResponseAppend(
                    requestToken: requestToken,
                    clientExchangePrivateKey: clientEphemeralPrivateKey,
                    hostExchangePublicKey: exchangePublicKey
                )
                return RequestTokenResponse(
                    response: response,
                    append: append
                )
            } catch {
                assertionFailure(error.localizedDescription)
                throw Twitter.API.Error.InternalError(message: "process requestToken response fail")
            }
        } catch {
            assertionFailure(error.localizedDescription)
            throw error
        }
    }
    
    public struct RequestTokenQuery {
        public let consumerKey: String
        public let hostPublicKey: Curve25519.KeyAgreement.PublicKey
        public let oauthEndpoint: String
        
        public init(consumerKey: String, hostPublicKey: Curve25519.KeyAgreement.PublicKey, oauthEndpoint: String) {
            self.consumerKey = consumerKey
            self.hostPublicKey = hostPublicKey
            self.oauthEndpoint = oauthEndpoint
        }
    }
    
    public struct RequestTokenResponse {
        public let response: CustomRequestTokenResponse
        public let append: CustomRequestTokenResponseAppend
    }
    
    struct CustomRequestTokenPayload: Codable {
        public let exchangePublicKey: String
        public let consumerKeyBox: String
        
        public enum CodingKeys: String, CodingKey {
            case exchangePublicKey = "exchange_public_key"
            case consumerKeyBox = "consumer_key_box"
        }
        
        init(exchangePublicKey: Curve25519.KeyAgreement.PublicKey, consumerKeyBox: ChaChaPoly.SealedBox) {
            self.exchangePublicKey = exchangePublicKey.rawRepresentation.base64EncodedString()
            self.consumerKeyBox = consumerKeyBox.combined.base64EncodedString()
        }
    }
    
    public struct CustomRequestTokenResponse: Codable {
        public let exchangePublicKey: String
        public let requestTokenBox: String
        
        enum CodingKeys: String, CodingKey, CaseIterable {
            case exchangePublicKey = "exchange_public_key"
            case requestTokenBox = "request_token_box"
        }
    }
    
    public struct CustomRequestTokenResponseAppend {
        public let requestToken: String
        public let clientExchangePrivateKey: Curve25519.KeyAgreement.PrivateKey
        public let hostExchangePublicKey: Curve25519.KeyAgreement.PublicKey
    }
    
    public struct CustomOAuthCallback: Codable {
        
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
        public let accessToken: String
        public let accessTokenSecret: String
        public let userID: String
        public let screenName: String
        public let consumerKey: String
        public let consumerSecret: String
        
        public enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case accessTokenSecret = "access_token_secret"
            case userID = "uesr_id"     // server typo and need keep it
            case screenName = "screen_name"
            case consumerKey = "consumer_key"
            case consumerSecret = "consumer_secret"
        }
    }
    
    
}
