//
//  TwitterAPI+OAuth.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-1.
//

import Foundation
import Combine

extension TwitterAPI.OAuth {
    
    static let authorizeEndpointURL = URL(string: "https://api.twitter.com/oauth/authorize")!
    static let requestTokenEndpointURL = URL(string: "https://twitter.mainasuk.com/oauth")!
    
    public static func requestToken(session: URLSession) -> AnyPublisher<RequestToken, Error> {
        let request = URLRequest(url: TwitterAPI.OAuth.requestTokenEndpointURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: TwitterAPI.timeoutInterval)
        return session.dataTaskPublisher(for: request)
            .map { data, _ in data }
            .decode(type: RequestToken.self, decoder: TwitterAPI.jsonDecoder)
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

extension TwitterAPI.OAuth {
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
}
