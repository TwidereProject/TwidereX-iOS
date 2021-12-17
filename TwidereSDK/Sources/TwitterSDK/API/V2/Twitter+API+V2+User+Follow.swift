//
//  Twitter+API+V2+User+Follow.swift
//  
//
//  Created by Cirno MainasuK on 2021-10-19.
//

import Foundation

// Request follow user
// https://developer.twitter.com/en/docs/twitter-api/users/follows/introduction
extension Twitter.API.V2.User.Follow {
    
    static func followEndpointURL(
        sourceUserID: Twitter.Entity.V2.User.ID
    ) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(sourceUserID)
            .appendingPathComponent("following")
    }
    
    public static func follow(
        session: URLSession,
        sourceUserID: Twitter.Entity.V2.User.ID,
        targetUserID: Twitter.Entity.V2.User.ID,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<FollowContent> {
        let query = FollowQuery(targetUserID: targetUserID)
        let request = Twitter.API.request(
            url: followEndpointURL(sourceUserID: sourceUserID),
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: FollowContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct FollowQuery: JSONEncodeQuery {
        public let targetUserID: Twitter.Entity.V2.User.ID
        
        enum CodingKeys: String, CodingKey {
            case targetUserID = "target_user_id"
        }
        
        public init(targetUserID: Twitter.Entity.V2.User.ID) {
            self.targetUserID = targetUserID
        }
        
        var queryItems: [URLQueryItem]? { nil }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
    }
    
    public struct FollowContent: Codable {
        public let data: ContentData
        
        public struct ContentData: Codable {
            public let following: Bool
            public let pendingFollow: Bool?
            
            enum CodingKeys: String, CodingKey {
                case following
                case pendingFollow = "pending_follow"
            }
            
        }
    }
    
}

// Cancel follow user
extension Twitter.API.V2.User.Follow {
    
    static func undoFollowEndpointURL(
        sourceUserID: Twitter.Entity.V2.User.ID,
        targetUserID: Twitter.Entity.V2.User.ID
    ) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(sourceUserID)
            .appendingPathComponent("following")
            .appendingPathComponent(targetUserID)
    }
    
    public static func undoFollow(
        session: URLSession,
        sourceUserID: Twitter.Entity.V2.User.ID,
        targetUserID: Twitter.Entity.V2.User.ID,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<FollowContent> {
        let url = undoFollowEndpointURL(sourceUserID: sourceUserID, targetUserID: targetUserID)
        let request = Twitter.API.request(
            url: url,
            method: .DELETE,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: FollowContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
}

extension Twitter.API.V2.User.Follow {
    public struct FriendshipListQuery: Query {
        public let userID: Twitter.Entity.V2.User.ID
        public let maxResults: Int
        public let paginationToken: String?
        
        public init(userID: Twitter.Entity.V2.User.ID, maxResults: Int, paginationToken: String?) {
            self.userID = userID
            self.maxResults = min(1000, max(10, maxResults))
            self.paginationToken = paginationToken
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(Twitter.Request.tweetsFields.queryItem)
            items.append(Twitter.Request.userFields.queryItem)
            items.append(URLQueryItem(name: "max_results", value: String(maxResults)))
            paginationToken.flatMap {
                items.append(URLQueryItem(name: "pagination_token", value: $0))
            }
            guard !items.isEmpty else { return nil }
            return items
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
    public struct FriendshipListContent: Codable {
        public let data: [Twitter.Entity.V2.User]?
        public let includes: Include?
        public let errors: [Twitter.Response.V2.ContentError]?
        public let meta: Meta
        
        public struct Include: Codable {
            public let tweets: [Twitter.Entity.V2.Tweet]?
        }
        
        public struct Meta: Codable {
            public let resultCount: Int
            public let nextToken: String?
            
            public enum CodingKeys: String, CodingKey {
                case resultCount = "result_count"
                case nextToken = "next_token"
            }
        }
    }
}

// Returns a list of users the specified userID following
// https://developer.twitter.com/en/docs/twitter-api/users/follows/api-reference/get-users-id-following
extension Twitter.API.V2.User.Follow {
    
    static func followingEndpointURL(userID: Twitter.Entity.V2.User.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(userID)
            .appendingPathComponent("following")
    }
    
    public static func followingList(
        session: URLSession,
        query: Twitter.API.V2.User.Follow.FriendshipListQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Follow.FriendshipListContent> {
        let request = Twitter.API.request(
            url: followingEndpointURL(userID: query.userID),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.API.V2.User.Follow.FriendshipListContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
}

// Returns a list of users who are followers of the specified user ID.
// https://developer.twitter.com/en/docs/twitter-api/users/follows/api-reference/get-users-id-followers
extension Twitter.API.V2.User.Follow {
    
    static func followerListEndpointURL(userID: Twitter.Entity.V2.User.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(userID)
            .appendingPathComponent("followers")
    }
    
    public static func followers(
        session: URLSession,
        query: Twitter.API.V2.User.Follow.FriendshipListQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Follow.FriendshipListContent> {
        let request = Twitter.API.request(
            url: followerListEndpointURL(userID: query.userID),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.API.V2.User.Follow.FriendshipListContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
}
