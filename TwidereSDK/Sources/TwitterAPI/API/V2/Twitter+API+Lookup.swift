//
//  Twitter+API+Lookup.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-15.
//

import Foundation
import Combine

extension Twitter.API.Lookup {
    
    static let tweetsLookupEndpointURL = Twitter.API.endpointV2URL.appendingPathComponent("tweets")
    
    public static func lookup(tweets: [Twitter.Entity.Tweet.ID], session: URLSession, authorization: Twitter.API.OAuth.Authorization) -> AnyPublisher<Twitter.Response<[Twitter.Entity.TweetV2]>, Error> {
        guard var components = URLComponents(string: tweetsLookupEndpointURL.absoluteString) else { fatalError() }
        
        let ids = tweets.joined(separator: ",")
        components.queryItems = [
            URLQueryItem(name: "ids", value: ids),
            Twitter.Request.TwitterFields.allCasesQueryItem,
            Twitter.Request.UserFields.allCasesQueryItem,
            Twitter.Request.Expansions.allCasesQueryItem,
            Twitter.Request.MediaFields.allCasesQueryItem,
            Twitter.Request.PlaceFields.allCasesQueryItem,
            Twitter.Request.PollFields.allCasesQueryItem,
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
                let value = try Twitter.API.decode(type: [Twitter.Entity.TweetV2].self, from: data, response: response)
                return Twitter.Response(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}
