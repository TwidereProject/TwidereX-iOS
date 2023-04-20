//
//  File.swift
//  
//
//  Created by Cirno MainasuK on 2020-11-2.
//

import Foundation
import Combine

extension Twitter.API.Friendships {

    static let showEndpointURL = Twitter.API.endpointURL.appendingPathComponent("friendships/show.json")        // 180 in 15m
    
    public static func friendship(
        session: URLSession,
        query: FriendshipQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.Entity.Relationship> {
        let request = Twitter.API.request(
            url: showEndpointURL,
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.Entity.Relationship.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct FriendshipQuery: Query {
        
        public let sourceID: Twitter.Entity.User.ID
        public let targetID: Twitter.Entity.User.ID
        
        public init(sourceID: Twitter.Entity.User.ID, targetID: Twitter.Entity.User.ID) {
            self.sourceID = sourceID
            self.targetID = targetID
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "source_id", value: sourceID))
            items.append(URLQueryItem(name: "target_id", value: targetID))
            guard !items.isEmpty else { return nil }
            return items
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
}

extension Twitter.API.Friendships {
    
    static let createEndpointURL = Twitter.API.endpointURL.appendingPathComponent("friendships/create.json")    // 400 in 1 day
    static let destroyEndpointURL = Twitter.API.endpointURL.appendingPathComponent("friendships/destroy.json")
    static let updateEndpointURL = Twitter.API.endpointURL.appendingPathComponent("friendships/update.json")
    
    @available(*, deprecated, message: "use V2")
    public static func friendships(session: URLSession, authorization: Twitter.API.OAuth.Authorization, queryKind: UpdateQueryType, query: FriendshipUpdateQuery) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        let url: URL = {
            switch queryKind {
            case .create: return createEndpointURL
            case .destroy: return destroyEndpointURL
            case .update: return updateEndpointURL
            }
        }()
        var request = Twitter.API.request(url: url, httpMethod: "POST", authorization: authorization, queryItems: query.queryItems)
        request.httpMethod = "POST"
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: Twitter.Entity.User.self, from: data, response: response)
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Twitter.API.Friendships {
    
    public enum UpdateQueryType {
        case create
        case destroy
        case update
    }
    
    public struct FriendshipUpdateQuery {
        public let userID: Twitter.Entity.User.ID
        
        public init(userID: Twitter.Entity.User.ID) {
            self.userID = userID
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "user_id", value: userID))
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
}
