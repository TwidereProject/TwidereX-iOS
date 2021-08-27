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
    
    public static func home(
        session: URLSession,
        query: TimelineQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.Tweet]> {
        let request = Twitter.API.request(
            url: homeTimelineEndpointURL,
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        do {
            let value = try Twitter.API.decode(type: [Twitter.Entity.Tweet].self, from: data, response: response)
            return Twitter.Response.Content(value: value, response: response)
        } catch {
            debugPrint(error)
            throw error
        }
    }
    
}

extension Twitter.API.Timeline {

    static let mentionTimelineEndpointURL = Twitter.API.endpointURL.appendingPathComponent("statuses/mentions_timeline.json")
    static let userTimelineEndpointURL = Twitter.API.endpointURL.appendingPathComponent("statuses/user_timeline.json")
    
}

extension Twitter.API.Timeline {
    @available(*, deprecated, message: "")
    public static func homeTimeline(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: TimelineQuery) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
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
    
    public static func mentionTimeline(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: TimelineQuery) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
        let request = Twitter.API.request(url: mentionTimelineEndpointURL, httpMethod: "GET", authorization: authorization, queryItems: query.queryItems)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: [Twitter.Entity.Tweet].self, from: data, response: response)
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func userTimeline(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: TimelineQuery) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
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

public protocol TimelineQueryType {
    var maxID: Twitter.Entity.Tweet.ID? { get }
    var sinceID: Twitter.Entity.Tweet.ID? { get }
}

extension Twitter.API.Timeline {
    public struct TimelineQuery: TimelineQueryType, Query {
        
        // share
        public let count: Int?
        public let maxID: Twitter.Entity.Tweet.ID?
        public let sinceID: Twitter.Entity.Tweet.ID?
        public let excludeReplies: Bool?
        
        // user timeline
        public let userID: Twitter.Entity.User.ID?
        
        // search
        public let query: String?
        
        public init(
            count: Int? = nil,
            userID: Twitter.Entity.User.ID? = nil,
            maxID: Twitter.Entity.Tweet.ID? = nil,
            sinceID: Twitter.Entity.Tweet.ID? = nil,
            excludeReplies: Bool? = nil,
            query: String? = nil
        ) {
            self.count = count
            self.userID = userID
            self.maxID = maxID
            self.sinceID = sinceID
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
            if let sinceID = self.sinceID {
                items.append(URLQueryItem(name: "since_id", value: sinceID))
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
        
        var formQueryItems: [URLQueryItem]? { nil }

    }
}
