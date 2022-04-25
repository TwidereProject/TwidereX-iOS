//
//  Twitter+API+V2+User+Mute.swift
//  
//
//  Created by MainasuK on 2021-12-6.
//

import Foundation

extension Twitter.API.V2.User {
    public enum Mute { }
}

// doc: https://developer.twitter.com/en/docs/twitter-api/users/mutes/introduction
extension Twitter.API.V2.User.Mute {
    
    static func muteEndpointURL(sourceUserID: Twitter.Entity.User.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(sourceUserID)
            .appendingPathComponent("muting")
    }
    
    public static func mute(
        session: URLSession,
        sourceUserID: Twitter.Entity.User.ID,
        query: MuteQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<MuteContent> {
        let request = Twitter.API.request(
            url: muteEndpointURL(sourceUserID: sourceUserID),
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: MuteContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct MuteQuery: JSONEncodeQuery {
        
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
    
    public struct MuteContent: Codable {
        public let data: ContentData
        
        public struct ContentData: Codable {
            public let muting: Bool
        }
    }
    
}

extension Twitter.API.V2.User.Mute {
    
    static func unmuteEndpointURL(
        sourceUserID: Twitter.Entity.User.ID,
        targetUserID: Twitter.Entity.User.ID
    ) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(sourceUserID)
            .appendingPathComponent("muting")
            .appendingPathComponent(targetUserID)
    }
    
    public static func unmute(
        session: URLSession,
        sourceUserID: Twitter.Entity.User.ID,
        targetUserID: Twitter.Entity.User.ID,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<MuteContent> {
        let url = unmuteEndpointURL(sourceUserID: sourceUserID, targetUserID: targetUserID)
        let request = Twitter.API.request(
            url: url,
            method: .DELETE,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: MuteContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
}
