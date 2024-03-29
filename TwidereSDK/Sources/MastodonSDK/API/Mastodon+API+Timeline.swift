//
//  Mastodon+API+Timeline.swift
//  Mastodon+API+Timeline
//
//  Created by Cirno MainasuK on 2021-8-27.
//

import Foundation

extension Mastodon.API.Timeline {
    static func homeTimelineEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("timelines/home")
    }
    
    /// View statuses from followed users.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.1
    /// # Last Update
    ///   2021/8/27
    /// # Reference
    ///   [Document](https://https://docs.joinmastodon.org/methods/timelines/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `TimelineQuery` with query parameters
    ///   - authorization: User token
    /// - Returns: `[Mastodon.Entity.Status]` nested in the response
    public static func home(
        session: URLSession,
        domain: String,
        query: TimelineQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let request = Mastodon.API.request(
            url: homeTimelineEndpointURL(domain: domain),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.Status].self, from: data, response: response)
        
        return Mastodon.Response.Content(value: value, response: response)
    }
}

extension Mastodon.API.Timeline {
    static func hashtagTimelineEndpointURL(domain: String, hashtag: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("timelines")
            .appendingPathComponent("tag")
            .appendingPathComponent(hashtag)
    }
    
    /// View public statuses containing the given hashtag.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.2
    /// # Last Update
    ///   2021/11/9
    /// # Reference
    ///   [Document](https://https://docs.joinmastodon.org/methods/timelines/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - hashtag: Content of a #hashtag, not including # symbol.
    ///   - query: `TimelineQuery` with query parameters
    ///   - authorization: User token, auth is required if public preview is disabled
    /// - Returns: `[Mastodon.Entity.Status]` nested in the response
    public static func hashtag(
        session: URLSession,
        domain: String,
        hashtag: String,
        query: TimelineQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let request = Mastodon.API.request(
            url: hashtagTimelineEndpointURL(domain: domain, hashtag: hashtag),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.Status].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
}

extension Mastodon.API.Timeline {
    static func publicTimelineEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("timelines")
            .appendingPathComponent("public")
    }
    
    /// Public timeline.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.4
    /// # Last Update
    ///   2022/1/13
    /// # Reference
    ///   [Document](https://https://docs.joinmastodon.org/methods/timelines/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `TimelineQuery` with query parameters
    ///   - authorization: User token, auth is required if public preview is disabled
    /// - Returns: `[Mastodon.Entity.Status]` nested in the response
    public static func `public`(
        session: URLSession,
        domain: String,
        query: TimelineQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let request = Mastodon.API.request(
            url: publicTimelineEndpointURL(domain: domain),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.Status].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
}

extension Mastodon.API.Timeline {
    static func listTimelineEndpointURL(
        domain: String,
        listID: Mastodon.Entity.List.ID
    ) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("timelines")
            .appendingPathComponent("list")
            .appendingPathComponent(listID)
    }
    
    /// View statuses in the given list timeline.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.2
    /// # Last Update
    ///   2022/3/8
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/timelines/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `TimelineQuery` with query parameters
    ///   - authorization: User token
    /// - Returns: `[Mastodon.Entity.Status]` nested in the response
    public static func list(
        session: URLSession,
        domain: String,
        listID: Mastodon.Entity.List.ID,
        query: TimelineQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let request = Mastodon.API.request(
            url: listTimelineEndpointURL(domain: domain, listID: listID),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.Status].self, from: data, response: response)
        
        return Mastodon.Response.Content(value: value, response: response)
    }
}

public protocol TimelineQueryType {
    var maxID: Mastodon.Entity.Status.ID? { get }
    var sinceID: Mastodon.Entity.Status.ID? { get }
}

extension Mastodon.API.Timeline {
    public struct TimelineQuery: Query, TimelineQueryType {
        public let local: Bool?
        public let remote: Bool?
        public let onlyMedia: Bool?
        public let maxID: Mastodon.Entity.Status.ID?
        public let sinceID: Mastodon.Entity.Status.ID?
        public let minID: Mastodon.Entity.Status.ID?
        public let limit: Int?
        
        public init(
            local: Bool? = nil,
            remote: Bool? = nil,
            onlyMedia: Bool? = nil,
            maxID: Mastodon.Entity.Status.ID? = nil,
            sinceID: Mastodon.Entity.Status.ID? = nil,
            minID: Mastodon.Entity.Status.ID? = nil,
            limit: Int? = nil
        ) {
            self.local = local
            self.remote = remote
            self.onlyMedia = onlyMedia
            self.maxID = maxID
            self.sinceID = sinceID
            self.minID = minID
            self.limit = limit
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            local.flatMap { items.append(URLQueryItem(name: "local", value: $0.queryItemValue)) }
            remote.flatMap { items.append(URLQueryItem(name: "remote", value: $0.queryItemValue)) }
            onlyMedia.flatMap { items.append(URLQueryItem(name: "only_media", value: $0.queryItemValue)) }
            maxID.flatMap { items.append(URLQueryItem(name: "max_id", value: $0)) }
            sinceID.flatMap { items.append(URLQueryItem(name: "since_id", value: $0)) }
            minID.flatMap { items.append(URLQueryItem(name: "min_id", value: $0)) }
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            guard !items.isEmpty else { return nil }
            return items
        }
        
        var body: Data? {
            return nil 
        }
    }
}
