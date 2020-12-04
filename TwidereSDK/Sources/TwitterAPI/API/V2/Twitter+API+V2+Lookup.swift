//
//  Twitter+API+V2+Lookup.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-15.
//

import Foundation
import Combine

extension Twitter.API.V2.Lookup {
    
    static let tweetsEndpointURL = Twitter.API.endpointV2URL.appendingPathComponent("tweets")
    
    public static func tweets(tweetIDs: [Twitter.Entity.Tweet.ID], session: URLSession, authorization: Twitter.API.OAuth.Authorization) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.Lookup.Content>, Error> {
        guard var components = URLComponents(string: tweetsEndpointURL.absoluteString) else { fatalError() }
        
        let ids = tweetIDs.joined(separator: ",")
        components.queryItems = [
            Twitter.Request.expansions.queryItem,
            Twitter.Request.tweetsFields.queryItem,
            Twitter.Request.userFields.queryItem,
            Twitter.Request.mediaFields.queryItem,
            URLQueryItem(name: "ids", value: ids),
        ]
        
        guard let requestURL = components.url else { fatalError() }
        var request = URLRequest(
            url: requestURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: Twitter.API.timeoutInterval
        )
        request.setValue(
            authorization.authorizationHeader(requestURL: requestURL, httpMethod: "GET"),
            forHTTPHeaderField: Twitter.API.OAuth.authorizationField
        )
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: Twitter.API.V2.Lookup.Content.self, from: data, response: response)
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Twitter.API.V2.Lookup {
    public struct Content: Codable {
        public let data: [Twitter.Entity.V2.Tweet]?
        public let includes: Include?
        
        public struct Include: Codable {
            public let users: [Twitter.Entity.V2.User]?
            public let tweets: [Twitter.Entity.V2.Tweet]?
            public let media: [Twitter.Entity.V2.Media]?
        }
    }
}
