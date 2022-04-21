//
//  Twitter+API+OAuth.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-1.
//

import os.log
import Foundation
import Combine
import CryptoKit

extension Twitter.API.OAuth {
    
    static let requestTokenEndpointURL = URL(string: "https://api.twitter.com/oauth/request_token")!
    static let authorizeEndpointURL = URL(string: "https://api.twitter.com/oauth/authorize")!

}

extension Twitter.API.OAuth {
    
    public static func requestToken(
        session: URLSession,
        query: Twitter.API.OAuth.RequestTokenQueryContext
    ) async throws -> Twitter.API.OAuth.RequestTokenResponseContext {
        switch query {
        case .standard(let query):
            let response = try await Twitter.API.OAuth.RequestToken.Standard.requestToken(
                session: session,
                query: query
            )
            return .standard(response)
        case .relay(let query):
            let response = try await Twitter.API.OAuth.RequestToken.Relay.requestToken(
                session: session,
                query: query
            )
            return .relay(response)
        }
    }
    
    public enum RequestTokenQueryContext {
        case standard(query: Twitter.API.OAuth.RequestToken.Standard.RequestTokenQuery)
        case relay(query: Twitter.API.OAuth.RequestToken.Relay.RequestTokenQuery)
    }
    
    public enum RequestTokenResponseContext {
        case standard(Twitter.API.OAuth.RequestToken.Standard.RequestTokenResponse)
        case relay(Twitter.API.OAuth.RequestToken.Relay.RequestTokenResponse)
    }
    
}

extension Twitter.API.OAuth {
    
    static var authorizationField = "Authorization"
    
    static func authorizationHeader(
        requestURL url: URL,
        requestFormQueryItems formQueryItems: [URLQueryItem]?,
        httpMethod: String,
        callbackURL: URL?,
        consumerKey: String,
        consumerSecret: String,
        oauthToken: String?,
        oauthTokenSecret: String?
    ) -> String {
        var authorizationParameters = Dictionary<String, String>()
        authorizationParameters["oauth_version"] = "1.0"
        authorizationParameters["oauth_callback"] = callbackURL?.absoluteString
        authorizationParameters["oauth_consumer_key"] = consumerKey
        authorizationParameters["oauth_signature_method"] = "HMAC-SHA1"
        authorizationParameters["oauth_timestamp"] = String(Int(Date().timeIntervalSince1970))
        authorizationParameters["oauth_nonce"] = UUID().uuidString
        
        authorizationParameters["oauth_token"] = oauthToken
        
        authorizationParameters["oauth_signature"] = oauthSignature(
            requestURL: url,
            requestFormQueryItems: formQueryItems,
            httpMethod: httpMethod,
            consumerSecret: consumerSecret,
            parameters: authorizationParameters,
            oauthTokenSecret: oauthTokenSecret
        )
        
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
    
    static func oauthSignature(
        requestURL url: URL,
        requestFormQueryItems
        formQueryItems: [URLQueryItem]?,
        httpMethod: String,
        consumerSecret: String,
        parameters: Dictionary<String, String>,
        oauthTokenSecret: String?
    ) -> String {
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

    public struct Authorization: Hashable {
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
    
    public static func authorizeURL(requestToken: String) -> URL {
        var urlComponents = URLComponents(string: authorizeEndpointURL.absoluteString)!
        urlComponents.queryItems = [
            URLQueryItem(name: "oauth_token", value: requestToken),
        ]
        return urlComponents.url!
    }

}
