//
//  Twitter+API+OAuth.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-1.
//

import os.log
import Foundation
import CryptoKit
import Combine

public protocol OAuthExchangeProvider: class {
    func oauthExcahnge() -> Twitter.API.OAuth.OAuthExchange
}

extension Twitter.API.OAuth {
    
    static let requestTokenEndpointURL = URL(string: "https://api.twitter.com/oauth/request_token")!
    static let authorizeEndpointURL = URL(string: "https://api.twitter.com/oauth/authorize")!
    static let accessTokenURL = URL(string: "https://api.twitter.com/oauth/access_token")!
    
    public static func requestToken(session: URLSession, oauthExchangeProvider: OAuthExchangeProvider) -> AnyPublisher<OAuthRequestTokenExchange, Error> {
        let oauthExchange = oauthExchangeProvider.oauthExcahnge()
        switch oauthExchange {
        case .pin(let consumerKey, let consumerKeySecret):
            let request = Twitter.API.OAuth.requestTokenURLRequest(consumerKey: consumerKey, consumerSecret: consumerKeySecret)
            return session.dataTaskPublisher(for: request)
                .tryMap { data, response -> OAuthRequestTokenExchange in
                    let templateURLString = Twitter.API.OAuth.requestTokenEndpointURL.absoluteString
                    guard let body = String(data: data, encoding: .utf8),
                          let components = URLComponents(string: templateURLString + "?" + body),
                          let requestTokenResponse = RequestTokenResponse(queryItems: components.queryItems ?? []) else {
                        throw Twitter.API.Error.InternalError(message: "process requestToken response fail")
                    }
                    return .requestTokenResponse(requestTokenResponse)
                }
                .eraseToAnyPublisher()
            
        case .custom(let consumerKey, let hostPublicKey, let oauthEndpoint):
            os_log("%{public}s[%{public}ld], %{public}s: request token %s", ((#file as NSString).lastPathComponent), #line, #function, oauthEndpoint)

            let clientEphemeralPrivateKey = Curve25519.KeyAgreement.PrivateKey()
            let clientEphemeralPublicKey = clientEphemeralPrivateKey.publicKey
            do {
                let sharedSecret = try clientEphemeralPrivateKey.sharedSecretFromKeyAgreement(with: hostPublicKey)
                let salt = clientEphemeralPublicKey.rawRepresentation + sharedSecret.withUnsafeBytes { Data($0) }
                let wrapKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: salt, sharedInfo: Data("request token exchange".utf8), outputByteCount: 32)
                let consumerKeyBox = try ChaChaPoly.seal(Data(consumerKey.utf8), using: wrapKey)
                let requestTokenRequest = RequestTokenRequest(exchangePublicKey: clientEphemeralPublicKey, consumerKeyBox: consumerKeyBox)
                
                var request = URLRequest(url: URL(string: oauthEndpoint + "/oauth/request_token")!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Twitter.API.timeoutInterval)
                request.httpMethod = "POST"
                request.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(requestTokenRequest)

                return session.dataTaskPublisher(for: request)
                    .tryMap { data, _ -> OAuthRequestTokenExchange in
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
                            let sealedbox = try ChaChaPoly.SealedBox(combined: combinedData)
                            let requestTokenData = try ChaChaPoly.open(sealedbox, using: wrapKey)
                            guard let requestToken = String(data: requestTokenData, encoding: .utf8) else {
                                throw Twitter.API.Error.InternalError(message: "invalid requestToken response")
                            }
                            let append = CustomRequestTokenResponseAppend(
                                requestToken: requestToken,
                                clientExchangePrivateKey: clientEphemeralPrivateKey,
                                hostExchangePublicKey: exchangePublicKey
                            )
                            return .customRequestTokenResponse(response, append: append)
                        } catch {
                            assertionFailure(error.localizedDescription)
                            throw Twitter.API.Error.InternalError(message: "process requestToken response fail")
                        }
                    }
                    .eraseToAnyPublisher()
            } catch {
                assertionFailure(error.localizedDescription)
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
    }
    
    public static func autenticateURL(requestToken: String) -> URL {
        var urlComponents = URLComponents(string: authorizeEndpointURL.absoluteString)!
        urlComponents.queryItems = [
            URLQueryItem(name: "oauth_token", value: requestToken),
        ]
        return urlComponents.url!
    }
    
    static func requestTokenURLRequest(consumerKey: String, consumerSecret: String) -> URLRequest {
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
            consumerSecret: consumerSecret,
            oauthToken: nil,
            oauthTokenSecret: nil
        )
        request.setValue(authorizationHeader, forHTTPHeaderField: Twitter.API.OAuth.authorizationField)
        return request
    }
    
}

extension Twitter.API.OAuth {

    public static func accessToken(session: URLSession, consumerKey: String, consumerSecret: String, requestToken: String, pinCode: String) -> AnyPublisher<AccessTokenResponse, Error> {
        let request = Twitter.API.OAuth.accessTokenURLRequest(consumerKey: consumerKey, consumerSecret: consumerSecret, requestToken: requestToken, pinCode: pinCode)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> AccessTokenResponse in
                guard let body = String(data: data, encoding: .utf8),
                      let accessTokenResponse = AccessTokenResponse(urlEncodedForm: body) else {
                    throw Twitter.API.Error.InternalError(message: "process requestToken response fail")
                }
                return accessTokenResponse
            }
            .eraseToAnyPublisher()

    }
    
    static func accessTokenURLRequest(consumerKey: String, consumerSecret: String, requestToken: String, pinCode: String) -> URLRequest {
        var components = URLComponents(string: Twitter.API.OAuth.accessTokenURL.absoluteString)!
        let queryItems = [
            URLQueryItem(name: "oauth_token", value: requestToken),
            URLQueryItem(name: "oauth_verifier", value: pinCode)
        ]
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
            consumerSecret: consumerSecret,
            oauthToken: requestToken,
            oauthTokenSecret: nil
        )
        request.setValue(authorizationHeader, forHTTPHeaderField: Twitter.API.OAuth.authorizationField)
        return request
    }
    
}

extension Twitter.API.OAuth {
    
    public struct RequestTokenRequest: Codable {
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
    
    public struct RequestTokenResponse: Codable {
        public let oauthToken: String
        public let oauthTokenSecret: String
        public let oauthCallbackConfirmed: Bool
        
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
        
        public enum CodingKeys: String, CodingKey {
            case oauthToken = "oauth_token"
            case oauthTokenSecret = "oauth_token_secret"
            case oauthCallbackConfirmed = "oauth_callback_confirmed"
        }
    }
    
    public struct CustomRequestTokenResponse: Codable {
        let exchangePublicKey: String
        let requestTokenBox: String
                
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
    
    public struct OAuthCallbackResponse: Codable {
        
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
    
    public struct AccessTokenResponse: Codable {
        public let oauthToken: String
        public let oauthTokenSecret: String
        public let userID: String
        public let screenName: String
        
        enum CodingKeys: String, CodingKey, CaseIterable {
            case oauthToken = "oauth_token"
            case oauthTokenSecret = "oauth_token_secret"
            case userID = "user_id"
            case screenName = "screen_name"
        }
        
        init?(urlEncodedForm form: String) {
            var dict: [String: String] = [:]
            for component in form.components(separatedBy: "&") {
                let tuple = component.components(separatedBy: "=")
                for key in CodingKeys.allCases {
                    if tuple[0] == key.rawValue { dict[key.rawValue] = tuple[1] }
                }
            }
            
            guard let oauthToken = dict[CodingKeys.oauthToken.rawValue],
                  let oauthTokenSecret = dict[CodingKeys.oauthTokenSecret.rawValue],
                  let userID = dict[CodingKeys.userID.rawValue],
                  let screenName = dict[CodingKeys.screenName.rawValue] else
            {
                return nil
            }
            
            self.oauthToken = oauthToken
            self.oauthTokenSecret = oauthTokenSecret
            self.userID = userID
            self.screenName = screenName
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
            case userID = "uesr_id"
            case screenName = "screen_name"
            case consumerKey = "consumer_key"
            case consumerSecret = "consumer_secret"
        }
    }
    
    public struct Authorization {
        public let consumerKey: String
        public let consumerSecret: String
        public let accessToken: String
        public let accessTokenSecret: String
                
        public init(consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String) {
            self.consumerKey = consumerKey
            self.consumerSecret = consumerSecret
            self.accessToken = accessToken
            self.accessTokenSecret = accessTokenSecret
        }
        
        func authorizationHeader(requestURL url: URL, requestFormQueryItems: [URLQueryItem]? = nil, httpMethod: String) -> String {
            return Twitter.API.OAuth.authorizationHeader(
                requestURL: url,
                requestFormQueryItems: requestFormQueryItems,
                httpMethod: httpMethod,
                callbackURL: nil,
                consumerKey: consumerKey,
                consumerSecret: consumerSecret,
                oauthToken: accessToken,
                oauthTokenSecret: accessTokenSecret
            )
        }
    }
    
}

extension Twitter.API.OAuth {
    
    static var authorizationField = "Authorization"
    
    static func authorizationHeader(requestURL url: URL, requestFormQueryItems formQueryItems: [URLQueryItem]?, httpMethod: String, callbackURL: URL?, consumerKey: String, consumerSecret: String, oauthToken: String?, oauthTokenSecret: String?) -> String {
        var authorizationParameters = Dictionary<String, String>()
        authorizationParameters["oauth_version"] = "1.0"
        authorizationParameters["oauth_callback"] = callbackURL?.absoluteString
        authorizationParameters["oauth_consumer_key"] = consumerKey
        authorizationParameters["oauth_signature_method"] = "HMAC-SHA1"
        authorizationParameters["oauth_timestamp"] = String(Int(Date().timeIntervalSince1970))
        authorizationParameters["oauth_nonce"] = UUID().uuidString
        
        authorizationParameters["oauth_token"] = oauthToken
        
        authorizationParameters["oauth_signature"] = oauthSignature(requestURL: url, requestFormQueryItems: formQueryItems, httpMethod: httpMethod, consumerSecret: consumerSecret, parameters: authorizationParameters, oauthTokenSecret: oauthTokenSecret)
        
        var parameterComponents = authorizationParameters.urlEncodedQuery.components(separatedBy: "&") as [String]
        parameterComponents.sort { $0 < $1 }
        
        var headerComponents = [String]()
        for component in parameterComponents {
            let subcomponent = component.components(separatedBy: "=") as [String]
            if subcomponent.count == 2 {
                headerComponents.append("\(subcomponent[0])=\"\(subcomponent[1])\"")
            }
        }
        
        return "OAuth " + headerComponents.joined(separator: ", ")
    }
    
    static func oauthSignature(requestURL url: URL, requestFormQueryItems formQueryItems: [URLQueryItem]?, httpMethod: String, consumerSecret: String, parameters: Dictionary<String, String>, oauthTokenSecret: String?) -> String {
        let encodedConsumerSecret = consumerSecret.urlEncoded
        let encodedTokenSecret = oauthTokenSecret?.urlEncoded ?? ""
        let signingKey = "\(encodedConsumerSecret)&\(encodedTokenSecret)"
        
        var parameters = parameters
        
        var components = URLComponents(string: url.absoluteString)!
        for item in components.queryItems ?? [] {
            parameters[item.name] = item.value
        }
        for item in formQueryItems ?? [] {
            parameters[item.name] = item.value
        }

        components.queryItems = nil
        let baseURL = components.url!
        
        var parameterComponents = parameters.urlEncodedQuery.components(separatedBy: "&")
        parameterComponents.sort {
            let p0 = $0.components(separatedBy: "=")
            let p1 = $1.components(separatedBy: "=")
            if p0.first == p1.first { return p0.last ?? "" < p1.last ?? "" }
            return p0.first ?? "" < p1.first ?? ""
        }
        
        let parameterString = parameterComponents.joined(separator: "&")
        let encodedParameterString = parameterString.urlEncoded
        
        let encodedURL = baseURL.absoluteString.urlEncoded
        
        let signatureBaseString = "\(httpMethod)&\(encodedURL)&\(encodedParameterString)"
        let message = Data(signatureBaseString.utf8)
        
        let key = SymmetricKey(data: Data(signingKey.utf8))
        var hmac: HMAC<Insecure.SHA1> = HMAC(key: key)
        hmac.update(data: message)
        let mac = hmac.finalize()
        
        let base64EncodedMac = Data(mac).base64EncodedString()
        return base64EncodedMac
    }
    
}

extension Twitter.API.OAuth {
    public enum OAuthExchange {
        case pin(consumerKey: String, consumerKeySecret: String)
        case custom(consumerKey: String, hostPublicKey: Curve25519.KeyAgreement.PublicKey, oauthEndpoint: String)
    }
    
    public enum OAuthRequestTokenExchange {
        case requestTokenResponse(RequestTokenResponse)
        case customRequestTokenResponse(CustomRequestTokenResponse, append: CustomRequestTokenResponseAppend)
    }
}
