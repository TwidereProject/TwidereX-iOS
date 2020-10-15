//
//  Twitter+API+Statuses.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-15.
//

import Foundation
import Combine

extension Twitter.API.Statuses {

    static func retweetEndpointURL(tweetID: Twitter.Entity.Tweet.ID) -> URL { return Twitter.API.endpointURL.appendingPathComponent("statuses/retweet/\(tweetID).json")
    }
    
    static func unretweetEndpointURL(tweetID: Twitter.Entity.Tweet.ID) -> URL { return Twitter.API.endpointURL.appendingPathComponent("statuses/unretweet/\(tweetID).json")
    }
    
    public static func retweet(session: URLSession, authorization: Twitter.API.OAuth.Authorization, retweetKind: RetweetKind, query: Query) -> AnyPublisher<Twitter.Response<Twitter.Entity.Tweet>, Error> {
        let url: URL = {
            switch retweetKind {
            case .retweet: return retweetEndpointURL(tweetID: query.id)
            case .unretweet: return unretweetEndpointURL(tweetID: query.id)
            }
        }()
        var request = Twitter.API.request(url: url, httpMethod: "POST", authorization: authorization, queryItems: query.queryItems)
        request.httpMethod = "POST"
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: Twitter.Entity.Tweet.self, from: data, response: response)
                return Twitter.Response(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }

}

extension Twitter.API.Statuses {
    
    public enum RetweetKind {
        case retweet
        case unretweet
    }
    
    public struct Query {
        public let id: Twitter.Entity.Tweet.ID
        
        public init(id: Twitter.Entity.Tweet.ID) {
            self.id = id
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "id", value: id))
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
}
