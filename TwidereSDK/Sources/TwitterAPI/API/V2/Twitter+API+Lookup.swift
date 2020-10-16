//
//  Twitter+API+Lookup.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-15.
//

import Foundation
import Combine

extension Twitter.API.Lookup {
    
    static let tweetsEndpointURL = Twitter.API.endpointV2URL.appendingPathComponent("tweets")
    
    public static func tweets(tweetIDs: [Twitter.Entity.Tweet.ID], session: URLSession, authorization: Twitter.API.OAuth.Authorization) -> AnyPublisher<Twitter.Response<Twitter.API.Lookup.Content>, Error> {
        guard var components = URLComponents(string: tweetsEndpointURL.absoluteString) else { fatalError() }
        
        let ids = tweetIDs.joined(separator: ",")
        let tweetFields: [Twitter.Request.TwitterFields] = [
            .authorID, .conversationID
        ]
        components.queryItems = [
            URLQueryItem(name: "ids", value: ids),
            tweetFields.queryItem,
//            Twitter.Request.UserFields.allCasesQueryItem,
//            Twitter.Request.Expansions.allCasesQueryItem,
//            Twitter.Request.MediaFields.allCasesQueryItem,
//            Twitter.Request.PlaceFields.allCasesQueryItem,
//            Twitter.Request.PollFields.allCasesQueryItem,
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
                let value = try Twitter.API.decode(type: Twitter.API.Lookup.Content.self, from: data, response: response)
                return Twitter.Response(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Twitter.API.Lookup {
    public struct Content: Codable {
        public let data: [Twitter.Entity.TweetV2]?
        public let includes: Include?
        
        public struct Include: Codable {
            public let users: [Twitter.Entity.UserV2]?
            public let tweets: [Twitter.Entity.TweetV2]?
            // public let media: [Twitter.Entity.UserV2]?
        }
    }
}

extension Twitter.API.ResponseContent {
    public convenience init(content: Twitter.API.Lookup.Content) {
        var tweetDict: [Twitter.Entity.TweetV2.ID: Twitter.Entity.TweetV2] = [:]
        for tweet in content.data ?? [] {
            guard tweetDict[tweet.id] == nil else {
                assertionFailure()
                continue
            }
            tweetDict[tweet.id] = tweet
        }
        for tweet in content.includes?.tweets ?? [] {
            guard tweetDict[tweet.id] == nil else {
                assertionFailure()
                continue
            }
            tweetDict[tweet.id] = tweet
        }
        
        var userDict: [Twitter.Entity.UserV2.ID: Twitter.Entity.UserV2] = [:]
        for user in content.includes?.users ?? [] {
            guard userDict[user.id] == nil else {
                assertionFailure()
                continue
            }
            
            userDict[user.id] = user
        }
        
        self.init(tweetDict: tweetDict, userDict: userDict)
    }
}
