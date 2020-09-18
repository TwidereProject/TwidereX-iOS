//
//  Twitter+API+OAuth.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-1.
//

import Foundation
import CryptoKit
import Combine

extension Twitter.API.OAuth {
    
    static let authorizeEndpointURL = URL(string: "https://api.twitter.com/oauth/authorize")!
    static let requestTokenEndpointURL = URL(string: "https://twitter.mainasuk.com/oauth")!
    
    public static func requestToken(session: URLSession) -> AnyPublisher<RequestToken, Error> {
        let request = URLRequest(url: Twitter.API.OAuth.requestTokenEndpointURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Twitter.API.timeoutInterval)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                try Twitter.API.decode(type: RequestToken.self, from: data, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func autenticateURL(requestToken: RequestToken) -> URL {
        var urlComponents = URLComponents(string: authorizeEndpointURL.absoluteString)!
        urlComponents.queryItems = [
            URLQueryItem(name: "oauth_token", value: requestToken.oauthToken),
        ]
        return urlComponents.url!
    }
    
}

extension Twitter.API.OAuth {
    
    public struct RequestToken: Codable {
        public let oauthToken: String
        public let oauthTokenSecret: String
        public let oauthCallbackConfirmed: Bool
        
        public enum CodingKeys: String, CodingKey {
            case oauthToken = "oauth_token"
            case oauthTokenSecret = "oauth_token_secret"
            case oauthCallbackConfirmed = "oauth_callback_confirmed"
        }
    }
    
    public struct Authentication: Codable {
        public let oauthToken: String
        public let oauthTokenSecret: String
        public let userID: String
        public let screenName: String
        public let consumerKey: String
        public let consumerSecret: String
        
        public init?(callbackURL url: URL) {
            guard let urlComponents = URLComponents(string: url.absoluteString) else { return nil }
            guard let queryItems = urlComponents.queryItems,
                  let oauthToken = queryItems.first(where: { $0.name == "oauth_token" })?.value,
                  let oauthTokenSecret = queryItems.first(where: { $0.name == "oauth_token_secret" })?.value,
                  let userID = queryItems.first(where: { $0.name == "user_id" })?.value,
                  let screenName = queryItems.first(where: { $0.name == "screen_name" })?.value,
                  let consumerKey = queryItems.first(where: { $0.name == "consumer_key" })?.value,
                  let consumerSecret = queryItems.first(where: { $0.name == "consumer_secret" })?.value else {
                return nil
            }
            self.oauthToken = oauthToken
            self.oauthTokenSecret = oauthTokenSecret
            self.userID = userID
            self.screenName = screenName
            self.consumerKey = consumerKey
            self.consumerSecret = consumerSecret
        }
        
        enum CodingKeys: String, CodingKey {
            case oauthToken = "oauth_token"
            case oauthTokenSecret = "oauth_token_secret"
            case userID = "user_id"
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
        
        func authorizationHeader(requestURL url: URL, httpMethod: String) -> String {
            return Twitter.API.OAuth.authorizationHeader(
                requestURL: url,
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
    
    static func authorizationHeader(requestURL url: URL, httpMethod: String, callbackURL: URL?, consumerKey: String, consumerSecret: String, oauthToken: String?, oauthTokenSecret: String?) -> String {
        var authorizationParameters = Dictionary<String, String>()
        authorizationParameters["oauth_version"] = "1.0"
        authorizationParameters["oauth_callback"] = callbackURL?.absoluteString
        authorizationParameters["oauth_consumer_key"] = consumerKey
        authorizationParameters["oauth_signature_method"] = "HMAC-SHA1"
        authorizationParameters["oauth_timestamp"] = String(Int(Date().timeIntervalSince1970))
        authorizationParameters["oauth_nonce"] = UUID().uuidString
        
        authorizationParameters["oauth_token"] = oauthToken
        
        authorizationParameters["oauth_signature"] = oauthSignature(requestURL: url, httpMethod: httpMethod, consumerSecret: consumerSecret, parameters: authorizationParameters, oauthTokenSecret: oauthTokenSecret)
        
        
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
    
    static func oauthSignature(requestURL url: URL, httpMethod: String, consumerSecret: String, parameters: Dictionary<String, String>, oauthTokenSecret: String?) -> String {
        let encodedConsumerSecret = consumerSecret.urlEncoded
        let encodedTokenSecret = oauthTokenSecret?.urlEncoded ?? ""
        let signingKey = "\(encodedConsumerSecret)&\(encodedTokenSecret)"
        
        var parameters = parameters
        
        var components = URLComponents(string: url.absoluteString)!
        for item in components.queryItems ?? [] {
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

// MARK: - Helper

extension String {
    
    var urlEncoded: String {
        let customAllowedSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return self.addingPercentEncoding(withAllowedCharacters: customAllowedSet)!
    }
    
}

extension Dictionary {
    
    var queryString: String {
        var parts = [String]()
        
        for (key, value) in self {
            let query: String = "\(key)=\(value)"
            parts.append(query)
        }
        
        return parts.joined(separator: "&")
    }
    
    var urlEncodedQuery: String {
        var parts = [String]()
        
        for (key, value) in self {
            let keyString = "\(key)".urlEncoded
            let valueString = "\(value)".urlEncoded
            let query = "\(keyString)=\(valueString)"
            parts.append(query)
        }
        
        return parts.joined(separator: "&")
    }
    
}
