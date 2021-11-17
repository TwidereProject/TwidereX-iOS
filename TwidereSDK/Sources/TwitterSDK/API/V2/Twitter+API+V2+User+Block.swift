//
//  Twitter+API+V2+User+Block.swift
//  
//
//  Created by Cirno MainasuK on 2021-10-21.
//

import Foundation

// doc: https://developer.twitter.com/en/docs/twitter-api/users/blocks/introduction
extension Twitter.API.V2.User.Block {
    
    // https://developer.twitter.com/en/docs/twitter-api/users/blocks/api-reference/post-users-user_id-blocking
    static func blockEndpointURL(sourceUserID: Twitter.Entity.User.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(sourceUserID)
            .appendingPathComponent("blocking")
    }
    
    public static func block(
        session: URLSession,
        sourceUserID: Twitter.Entity.User.ID,
        query: BlockQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<BlockContent> {
        let request = Twitter.API.request(
            url: blockEndpointURL(sourceUserID: sourceUserID),
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: BlockContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct BlockQuery: JSONEncodeQuery {
        
        public let targetUserID: Twitter.Entity.User.ID
        
        public init(targetUserID: Twitter.Entity.User.ID) {
            self.targetUserID = targetUserID
        }
        
        enum CodingKeys: String, CodingKey {
            case targetUserID = "target_user_id"
        }
        
        var queryItems: [URLQueryItem]? { nil }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
    }
    
    public struct BlockContent: Codable {
        public let data: ContentData
        
        public struct ContentData: Codable {
            public let blocking: Bool
        }
    }
    
}

extension Twitter.API.V2.User.Block {
    
    // https://developer.twitter.com/en/docs/twitter-api/users/blocks/api-reference/delete-users-user_id-blocking
    static func unblockEndpointURL(
        sourceUserID: Twitter.Entity.User.ID,
        targetUserID: Twitter.Entity.User.ID
    ) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(sourceUserID)
            .appendingPathComponent("blocking")
            .appendingPathComponent(targetUserID)
    }
    
    public static func unblock(
        session: URLSession,
        sourceUserID: Twitter.Entity.User.ID,
        targetUserID: Twitter.Entity.User.ID,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<BlockContent> {
        let url = unblockEndpointURL(sourceUserID: sourceUserID, targetUserID: targetUserID)
        let request = Twitter.API.request(
            url: url,
            method: .DELETE,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: BlockContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
}
