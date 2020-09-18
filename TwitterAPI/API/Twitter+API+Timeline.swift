//
//  Twitter+API+Timeline.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
import Combine

extension Twitter.API.Timeline {
    
    static let homeTimelineEndpointURL = Twitter.API.endpointURL.appendingPathComponent("statuses/home_timeline.json")
    
    public static func homeTimeline(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: Query) -> AnyPublisher<Twitter.Response<[Twitter.Entity.Tweet]>, Error> {
        var components = URLComponents(string: homeTimelineEndpointURL.absoluteString)!
        components.queryItems = query.queryItems
        let requestURL = components.url!
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
                let value = try Twitter.API.decode(type: [Twitter.Entity.Tweet].self, from: data, response: response)
                return Twitter.Response(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Twitter.API.Timeline {
    public struct Query {
        public let count: Int?
        
        public init(count: Int?) {
            self.count = count
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            if let count = self.count {
                items.append(URLQueryItem(name: "count", value: String(count)))
            }
            guard !items.isEmpty else { return nil }
            return items
        }
        
        
    }
}
