//
//  Twitter+API+Search.swift
//  
//
//  Created by Cirno MainasuK on 2021-1-20.
//

import Foundation
import Combine

extension Twitter.API.Search {

    static var tweetsEndpointURL = Twitter.API.endpointURL.appendingPathComponent("search/tweets.json")

    public static func tweets(
        session: URLSession,
        authorization: Twitter.API.OAuth.Authorization,
        query: Twitter.API.Timeline.Query
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Search>, Error> {
        let url = tweetsEndpointURL
        let request = Twitter.API.request(url: url, httpMethod: "GET", authorization: authorization, queryItems: query.queryItems, encodedQueryItems: query.encodedQueryItems)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: Twitter.Entity.Search.self, from: data, response: response)
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}
