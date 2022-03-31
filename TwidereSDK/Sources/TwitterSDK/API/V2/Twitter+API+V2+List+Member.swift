//
//  Twitter+API+V2+List+Member.swift
//  
//
//  Created by MainasuK on 2022-3-24.
//

import Foundation

// add: https://developer.twitter.com/en/docs/twitter-api/lists/list-members/api-reference/post-lists-id-members
extension Twitter.API.V2.List.Member {
    
    private static func addMemberEndpointURL(listID: Twitter.Entity.V2.List.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("lists")
            .appendingPathComponent(listID)
            .appendingPathComponent("members")
    }
    
    public static func add(
        session: URLSession,
        listID: Twitter.Entity.V2.List.ID,
        query: AddMemberQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.List.Member.AddMemberContent> {
        let request = Twitter.API.request(
            url: addMemberEndpointURL(listID: listID),
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.API.V2.List.Member.AddMemberContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct AddMemberQuery: JSONEncodeQuery {
        public let userID: Twitter.Entity.V2.User.ID
        
        enum CodingKeys: String, CodingKey {
            case userID = "user_id"
        }
        
        public init(userID: Twitter.Entity.V2.User.ID) {
            self.userID = userID
        }

        var queryItems: [URLQueryItem]? { nil }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
    }
    
    public struct AddMemberContent: Codable {
        public let data: ContentData
        
        public struct ContentData: Codable {
            public let isMember: Bool
            
            enum CodingKeys: String, CodingKey {
                case isMember = "is_member"
            }
        }
    }
    
}

// remove: https://developer.twitter.com/en/docs/twitter-api/lists/list-members/api-reference/delete-lists-id-members-user_id
extension Twitter.API.V2.List.Member {
    
    private static func removeMemberEndpointURL(
        listID: Twitter.Entity.V2.List.ID,
        userID: Twitter.Entity.V2.User.ID
    ) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("lists")
            .appendingPathComponent(listID)
            .appendingPathComponent("members")
            .appendingPathComponent(userID)
    }
    
    public static func remove(
        session: URLSession,
        listID: Twitter.Entity.V2.List.ID,
        userID: Twitter.Entity.V2.User.ID,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.List.Member.RemoveMemberContent> {
        let request = Twitter.API.request(
            url: removeMemberEndpointURL(listID: listID, userID: userID),
            method: .DELETE,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.API.V2.List.Member.RemoveMemberContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public typealias RemoveMemberContent = AddMemberContent
    
}

