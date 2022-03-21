//
//  Twitter+API+V2+List.swift
//  
//
//  Created by MainasuK on 2022-3-11.
//

import Foundation

// lookup: https://developer.twitter.com/en/docs/twitter-api/lists/list-lookup/api-reference/get-lists-id
extension Twitter.API.V2.List {
    
    private static func lookupEndpointURL(listID: Twitter.Entity.V2.List.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("lists")
            .appendingPathComponent(listID)
    }
    
    public static func lookup(
        session: URLSession,
        listID: Twitter.Entity.V2.List.ID,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.List.LookupContent> {
        let request = Twitter.API.request(
            url: lookupEndpointURL(listID: listID),
            method: .GET,
            query: LookupQuery(),
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.API.V2.List.LookupContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct LookupQuery: Query {

        var queryItems: [URLQueryItem]? {
            let items: [URLQueryItem] = [
                [Twitter.Request.Expansions.ownerID].queryItem,
                Twitter.Request.userFields.queryItem,
                Twitter.Request.listFields.queryItem,
            ]
            return items
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
    public struct LookupContent: Codable {
        public let data: Twitter.Entity.V2.List
        public let includes: Includes?
        
        public struct Includes: Codable {
            public let users: [Twitter.Entity.V2.User]
        }
    }
    
}

// https://developer.twitter.com/en/docs/twitter-api/lists/list-follows/api-reference/get-lists-id-followers
extension Twitter.API.V2.List {
    
    private static func followerEndpointURL(listID: Twitter.Entity.V2.List.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("lists")
            .appendingPathComponent(listID)
            .appendingPathComponent("followers")
    }
    
    public static func follower(
        session: URLSession,
        listID: Twitter.Entity.V2.List.ID,
        query: FollowerQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.List.FollowerContent> {
        let request = Twitter.API.request(
            url: followerEndpointURL(listID: listID),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.API.V2.List.FollowerContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct FollowerQuery: Query {
        public let maxResults: Int
        public let nextToken: String?
        
        public init(
            maxResults: Int = 20,
            nextToken: String?
        ) {
            self.maxResults = min(100, max(10, maxResults))
            self.nextToken = nextToken
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = [
                Twitter.Request.userFields.queryItem,
                URLQueryItem(name: "max_results", value: String(maxResults)),
            ]
            if let nextToken = nextToken {
                let item = URLQueryItem(name: "pagination_token", value: nextToken)
                items.append(item)
            }
            return items
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
    public struct FollowerContent: Codable {
        public let data: [Twitter.Entity.V2.User]?
        public let meta: Meta
        
        public struct Meta: Codable {
            public let resultCount: Int
            public let previousToken: String?
            public let nextToken: String?
            
            enum CodingKeys: String, CodingKey {
                case resultCount = "result_count"
                case previousToken = "previous_token"
                case nextToken = "next_token"
            }
        }
    }
    
}

// https://developer.twitter.com/en/docs/twitter-api/lists/list-members/api-reference/get-lists-id-members
extension Twitter.API.V2.List {
    
    private static func memberEndpointURL(listID: Twitter.Entity.V2.List.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("lists")
            .appendingPathComponent(listID)
            .appendingPathComponent("members")
    }
    
    public static func member(
        session: URLSession,
        listID: Twitter.Entity.V2.List.ID,
        query: MemberQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.List.MemberContent> {
        let request = Twitter.API.request(
            url: memberEndpointURL(listID: listID),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.API.V2.List.FollowerContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public typealias MemberQuery = FollowerQuery
    public typealias MemberContent = FollowerContent
    
}

// create: https://developer.twitter.com/en/docs/twitter-api/lists/manage-lists/api-reference/post-lists
extension Twitter.API.V2.List {
    
    private static func listsEndpointURL() -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("lists")
    }
    
    public static func create(
        session: URLSession,
        query: CreateQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.List.CreateContent> {
        let request = Twitter.API.request(
            url: listsEndpointURL(),
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.API.V2.List.CreateContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct CreateQuery: JSONEncodeQuery {
        public let name: String
        public let description: String?
        public let `private`: Bool?
        
        public init(
            name: String,
            description: String?,
            private: Bool?
        ) {
            self.name = name
            self.description = description
            self.private = `private`
        }
        
        var queryItems: [URLQueryItem]? { nil }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
    }
    
    public struct CreateContent: Codable {
        public let data: ContentData
        
        public struct ContentData: Codable {
            public let id: Twitter.Entity.V2.List.ID
            public let name: String
        }
    }
    
}
