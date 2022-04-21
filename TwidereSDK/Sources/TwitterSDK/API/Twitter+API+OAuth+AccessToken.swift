//
//  Twitter+API+OAuth+CustomRequestToken.swift
//  
//
//  Created by MainasuK on 2022-4-21.
//

import Foundation

extension Twitter.API.OAuth {
    public enum AccessToken { }
}

extension Twitter.API.OAuth.AccessToken {
    
    static let accessTokenURL = URL(string: "https://api.twitter.com/oauth/access_token")!

    public static func accessToken(
        session: URLSession,
        query: AccessTokenQuery
    ) async throws -> AccessTokenResponse {
        let request = accessTokenURLRequest(
            consumerKey: query.consumerKey,
            consumerSecret: query.consumerSecret,
            requestToken: query.requestToken,
            pinCode: query.pinCode
        )

        let (data, _) = try await session.data(for: request, delegate: nil)
        guard let body = String(data: data, encoding: .utf8),
              let accessTokenResponse = AccessTokenResponse(urlEncodedForm: body)
        else {
            throw Twitter.API.Error.InternalError(message: "process requestToken response fail")
        }
        
        return accessTokenResponse
    }
    
    static func accessTokenURLRequest(
        consumerKey: String,
        consumerSecret: String,
        requestToken: String,
        pinCode: String
    ) -> URLRequest {
        var components = URLComponents(string: accessTokenURL.absoluteString)!
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
    
    public struct AccessTokenQuery {
        public let consumerKey: String
        public let consumerSecret: String
        public let requestToken: String
        public let pinCode: String

        public init(
            consumerKey: String,
            consumerSecret: String,
            requestToken: String,
            pinCode: String
        ) {
            self.consumerKey = consumerKey
            self.consumerSecret = consumerSecret
            self.requestToken = requestToken
            self.pinCode = pinCode
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
    
}
