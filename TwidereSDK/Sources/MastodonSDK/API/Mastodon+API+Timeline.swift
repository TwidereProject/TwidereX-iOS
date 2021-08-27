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
    ///   - query: `HomeTimelineQuery` with query parameters
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `[Mastodon.Entity.Status]` nested in the response
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
