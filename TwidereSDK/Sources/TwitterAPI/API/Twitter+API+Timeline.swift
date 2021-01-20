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
    static let mentionTimelineEndpointURL = Twitter.API.endpointURL.appendingPathComponent("statuses/mentions_timeline.json")
    static let userTimelineEndpointURL = Twitter.API.endpointURL.appendingPathComponent("statuses/user_timeline.json")
    
    public static func homeTimeline(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: Query) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
        let request = Twitter.API.request(url: homeTimelineEndpointURL, httpMethod: "GET", authorization: authorization, queryItems: query.queryItems)
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
    
    public static func mentionTimeline(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: Query) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
        let request = Twitter.API.request(url: mentionTimelineEndpointURL, httpMethod: "GET", authorization: authorization, queryItems: query.queryItems)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: [Twitter.Entity.Tweet].self, from: data, response: response)
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func userTimeline(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: Query) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
        assert(query.userID != nil && query.userID != "")
        
        var components = URLComponents(string: userTimelineEndpointURL.absoluteString)!
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

extension Twitter.API.Timeline {
    public struct Query {
        // share
        public let count: Int?
        
        // user timeline
        public let userID: String?
        public let maxID: String?
        public let excludeReplies: Bool?
        
        // search
        public let query: String?
        
        public init(
            count: Int? = nil,
            userID: String? = nil,
            maxID: String? = nil,
            excludeReplies: Bool? = nil,
            query: String? = nil
        ) {
            self.count = count
            self.userID = userID
            self.maxID = maxID
            self.excludeReplies = excludeReplies
            self.query = query
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            if let count = self.count {
                items.append(URLQueryItem(name: "count", value: String(count)))
            }
            if let userID = self.userID {
                items.append(URLQueryItem(name: "user_id", value: userID))
            }
            if let maxID = self.maxID {
                items.append(URLQueryItem(name: "max_id", value: maxID))
            }
            if let excludeReplies = self.excludeReplies {
                items.append(URLQueryItem(name: "exclude_replies", value: excludeReplies ? "true" : "false"))
            }
            items.append(URLQueryItem(name: "include_ext_alt_text", value: "true"))
            items.append(URLQueryItem(name: "tweet_mode", value: "extended"))
            
            guard !items.isEmpty else { return nil }
            return items
        }
        
        var encodedQueryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            if let query = query {
                items.append(URLQueryItem(name: "q", value: query.urlEncoded))
            }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
}
