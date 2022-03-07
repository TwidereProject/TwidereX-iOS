//
//  Twitter+API+Users+List.swift
//  
//
//  Created by MainasuK on 2022-2-28.
//

import Foundation

// https://developer.twitter.com/en/docs/twitter-api/lists/list-lookup/api-reference/get-users-id-owned_lists
extension Twitter.API.V2.User.List {

    static func ownedListEndpointURL(userID: Twitter.Entity.V2.User.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(userID)
            .appendingPathComponent("owned_lists")
    }
    
    public static func onwedLists(
        session: URLSession,
        userID: Twitter.Entity.V2.User.ID,
        query: OwnedListsQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.List.OwnedListsContent> {
        let request = Twitter.API.request(
            url: ownedListEndpointURL(userID: userID),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: OwnedListsContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct OwnedListsQuery: Query {
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
                [Twitter.Request.Expansions.ownerID].queryItem,
                Twitter.Request.userFields.queryItem,
                Twitter.Request.listFields.queryItem,
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
    
    public struct OwnedListsContent: Codable {
        public let data: [Twitter.Entity.V2.List]?
        public let includes: Includes?
        public let meta: Meta
        
        public struct Includes: Codable {
            public let users: [Twitter.Entity.V2.User]
        }
        
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

// https://developer.twitter.com/en/docs/twitter-api/lists/list-follows/api-reference/get-users-id-followed_lists
extension Twitter.API.V2.User.List {

    static func followedListEndpointURL(userID: Twitter.Entity.V2.User.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(userID)
            .appendingPathComponent("followed_lists")
    }
    
    public static func followedLists(
        session: URLSession,
        userID: Twitter.Entity.V2.User.ID,
        query: FollowedListsQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.List.FollowedListsContent> {
        let request = Twitter.API.request(
            url: followedListEndpointURL(userID: userID),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: FollowedListsContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public typealias FollowedListsQuery = OwnedListsQuery
    public typealias FollowedListsContent = OwnedListsContent

}

// https://developer.twitter.com/en/docs/twitter-api/lists/list-members/api-reference/get-users-id-list_memberships
extension Twitter.API.V2.User.List {

    static func listMembershipsEndpointURL(userID: Twitter.Entity.V2.User.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(userID)
            .appendingPathComponent("list_memberships")
    }
    
    public static func listMemberships(
        session: URLSession,
        userID: Twitter.Entity.V2.User.ID,
        query: ListMembershipsQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.List.ListMembershipsContent> {
        let request = Twitter.API.request(
            url: listMembershipsEndpointURL(userID: userID),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: ListMembershipsContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public typealias ListMembershipsQuery = OwnedListsQuery
    public typealias ListMembershipsContent = OwnedListsContent

}
