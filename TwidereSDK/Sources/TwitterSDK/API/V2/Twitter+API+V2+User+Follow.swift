//
//  Twitter+API+V2+User+Follow.swift
//  
//
//  Created by Cirno MainasuK on 2021-10-19.
//

import Foundation

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
