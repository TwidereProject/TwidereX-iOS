//
//  Twitter+API+V2+Status+Delete.swift
//  
//
//  Created by MainasuK on 2021-12-16.
//

import Foundation

extension Twitter.API.V2.Status {
    public enum Delete { }
}

// doc: https://developer.twitter.com/en/docs/twitter-api/tweets/manage-tweets/introduction
extension Twitter.API.V2.Status.Delete {
    
    static func deleteEndpointURL(statusID: Twitter.Entity.V2.Tweet.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("tweets")
            .appendingPathComponent(statusID)
    }
    
    // https://developer.twitter.com/en/docs/twitter-api/users/blocks/api-reference/post-users-user_id-blocking
    public static func delete(
        session: URLSession,
        statusID: Twitter.Entity.V2.Tweet.ID,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<DeleteContent> {
        let request = Twitter.API.request(
            url: deleteEndpointURL(statusID: statusID),
            method: .DELETE,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: DeleteContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct DeleteContent: Codable {
        public let data: ContentData
        
        public struct ContentData: Codable {
            public let deleted: Bool
        }
    }
    
}
