//
//  Twitter+API+Lookup.swift
//  
//
//  Created by Cirno MainasuK on 2020-12-15.
//

import Foundation
import Combine

extension Twitter.API.Lookup {
    
    static let statusesLookupEndpointURL = Twitter.API.endpointURL.appendingPathComponent("statuses/lookup.json")
    
    public static func tweets(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: Query) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
        let request = Twitter.API.request(url: statusesLookupEndpointURL, httpMethod: "GET", authorization: authorization, queryItems: query.queryItems)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                do {
                    let value = try Twitter.API.decode(type: [Twitter.Entity.Tweet].self, from: data, response: response)
                    return Twitter.Response.Content(value: value, response: response)
                } catch {
                    debugPrint(error)
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }
}

extension Twitter.API.Lookup {
    public struct Query {
        public let ids: [String]
        
        public init(ids: [String]) {
            self.ids = ids
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            
            let ids = self.ids.joined(separator: ",")
            // "id" not typo
            items.append(URLQueryItem(name: "id", value: ids))
            items.append(URLQueryItem(name: "include_entities", value: "true"))
            items.append(URLQueryItem(name: "include_ext_alt_text", value: "true"))
            items.append(URLQueryItem(name: "tweet_mode", value: "extended"))
            
            guard !items.isEmpty else { return nil }
            return items
        }
    }
}
