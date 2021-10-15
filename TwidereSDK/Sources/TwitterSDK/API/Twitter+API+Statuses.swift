//
//  Twitter+API+Statuses.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-15.
//

import Foundation
import Combine

public protocol TimelineQueryType {
    var maxID: Twitter.Entity.Tweet.ID? { get }
    var sinceID: Twitter.Entity.Tweet.ID? { get }
}

extension Twitter.API.Statuses {
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
        var contentType: String? { nil }
        var body: Data? { nil }
        
    }
}


extension Twitter.API.Statuses {
    
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

extension Twitter.API.Statuses {
    
    static let userTimelineEndpointURL = Twitter.API.endpointURL.appendingPathComponent("statuses/user_timeline.json")
    
    public static func user(
        session: URLSession,
        query: TimelineQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.Tweet]> {
        let request = Twitter.API.request(
            url: userTimelineEndpointURL,
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


extension Twitter.API.Statuses {
    
    static var updateEndpointURL = Twitter.API.endpointURL.appendingPathComponent("statuses/update.json")
    static func retweetEndpointURL(tweetID: Twitter.Entity.Tweet.ID) -> URL { return Twitter.API.endpointURL.appendingPathComponent("statuses/retweet/\(tweetID).json") }
    static func unretweetEndpointURL(tweetID: Twitter.Entity.Tweet.ID) -> URL { return Twitter.API.endpointURL.appendingPathComponent("statuses/unretweet/\(tweetID).json") }
    static func destroyEndpointURL(tweetID: Twitter.Entity.Tweet.ID) -> URL { return Twitter.API.endpointURL.appendingPathComponent("statuses/destroy/\(tweetID).json") }
    
    public static func update(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: UpdateQuery) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Tweet>, Error> {
        let url = updateEndpointURL
        var request = Twitter.API.request(url: url, httpMethod: "POST", authorization: authorization, queryItems: query.queryItems, encodedQueryItems: query.encodedQueryItems)
        request.httpMethod = "POST"
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: Twitter.Entity.Tweet.self, from: data, response: response)
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func retweet(session: URLSession, authorization: Twitter.API.OAuth.Authorization, retweetKind: RetweetKind, query: RetweetQuery) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Tweet>, Error> {
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
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func destroy(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: DestroyQuery) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Tweet>, Error> {
        let url = destroyEndpointURL(tweetID: query.id)
        var request = Twitter.API.request(url: url, httpMethod: "POST", authorization: authorization, queryItems: query.queryItems)
        request.httpMethod = "POST"
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: Twitter.Entity.Tweet.self, from: data, response: response)
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Twitter.API.Statuses {
    
    public struct UpdateQuery {
        public let status: String
        public let inReplyToStatusID: Twitter.Entity.Tweet.ID?
        public let autoPopulateReplyMetadata: Bool?
        public let excludeReplyUserIDs: String?
        public let mediaIDs: String?
        public let latitude: Double?
        public let longitude: Double?
        public let placeID: String?
        
        public init(
            status: String,
            inReplyToStatusID: Twitter.Entity.Tweet.ID?,
            autoPopulateReplyMetadata: Bool?,
            excludeReplyUserIDs: String?,
            mediaIDs: String?,
            latitude: Double?,
            longitude: Double?,
            placeID: String?
        ) {
            self.status = status
            self.inReplyToStatusID = inReplyToStatusID
            self.autoPopulateReplyMetadata = autoPopulateReplyMetadata
            self.excludeReplyUserIDs = excludeReplyUserIDs
            self.mediaIDs = mediaIDs
            self.latitude = latitude
            self.longitude = longitude
            self.placeID = placeID
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            inReplyToStatusID.flatMap { items.append(URLQueryItem(name: "in_reply_to_status_id", value: $0)) }
            autoPopulateReplyMetadata.flatMap { items.append(URLQueryItem(name: "auto_populate_reply_metadata", value: $0 ? "true" : "false")) }
            excludeReplyUserIDs.flatMap { items.append(URLQueryItem(name: "exclude_reply_user_ids", value: $0)) }
            mediaIDs.flatMap { items.append(URLQueryItem(name: "media_ids", value: $0)) }
            latitude.flatMap { items.append(URLQueryItem(name: "lat", value: String($0))) }
            longitude.flatMap { items.append(URLQueryItem(name: "long", value: String($0))) }
            placeID.flatMap { items.append(URLQueryItem(name: "place_id", value: $0)) }
            guard !items.isEmpty else { return nil }
            return items
        }
        
        var encodedQueryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "status", value: status.urlEncoded))
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
    public enum RetweetKind {
        case retweet
        case unretweet
    }
    
    public struct RetweetQuery {
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
    
    public struct DestroyQuery {
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
