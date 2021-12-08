//
//  Twitter+API+V2+UserLookup.swift
//  
//
//  Created by Cirno MainasuK on 2020-11-27.
//

import Foundation
import Combine

extension Twitter.API.V2.UserLookup {
    
    static let usersEndpointURL = Twitter.API.endpointV2URL.appendingPathComponent("users")
    
    public static func users(
        session: URLSession,
        userIDs: [Twitter.Entity.User.ID],
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.UserLookup.Content> {
        let query = UserIDLookupQuery(userIDs: userIDs)
        let request = Twitter.API.request(
            url: usersEndpointURL,
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.API.V2.UserLookup.Content.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct UserIDLookupQuery: Query {
        public let userIDs: [Twitter.Entity.V2.User.ID]
        
        public init(userIDs: [Twitter.Entity.V2.User.ID]) {
            self.userIDs = userIDs
        }
        
        var queryItems: [URLQueryItem]? {
            let userIDs = userIDs.joined(separator: ",")
            let expansions: [Twitter.Request.Expansions] = [.pinnedTweetID]
            let tweetsFields: [Twitter.Request.TwitterFields] = [
                .attachments,
                .authorID,
                .contextAnnotations,
                .conversationID,
                .created_at,
                .entities,
                .geo,
                .id,
                .inReplyToUserID,
                .lang,
                .publicMetrics,
                .possiblySensitive,
                .referencedTweets,
                .source,
                .text,
                .withheld,
            ]
            let userFields: [Twitter.Request.UserFields] = [
                .createdAt,
                .description,
                .entities,
                .id,
                .location,
                .name,
                .pinnedTweetID,
                .profileImageURL,
                .protected,
                .publicMetrics,
                .url,
                .username,
                .verified,
                .withheld
            ]
            return [
                expansions.queryItem,
                tweetsFields.queryItem,
                userFields.queryItem,
                URLQueryItem(name: "ids", value: userIDs),
            ]
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
}

extension Twitter.API.V2.UserLookup {

    static let usersByEndpointURL = Twitter.API.endpointV2URL.appendingPathComponent("users/by")

    public static func users(
        session: URLSession,
        usernames: [String],
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.UserLookup.Content> {
        let query = UsernameLookupQuery(usernames: usernames)
        let request = Twitter.API.request(
            url: usersByEndpointURL,
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.API.V2.UserLookup.Content.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct UsernameLookupQuery: Query {
        public let usernames: [String]
        
        public init(usernames: [String]) {
            self.usernames = usernames
        }
        
        var queryItems: [URLQueryItem]? {
            let usernames = usernames.joined(separator: ",")
            let expansions: [Twitter.Request.Expansions] = [.pinnedTweetID]
            let tweetsFields: [Twitter.Request.TwitterFields] = [
                .attachments,
                .authorID,
                .contextAnnotations,
                .conversationID,
                .created_at,
                .entities,
                .geo,
                .id,
                .inReplyToUserID,
                .lang,
                .publicMetrics,
                .possiblySensitive,
                .referencedTweets,
                .source,
                .text,
                .withheld,
            ]
            let userFields: [Twitter.Request.UserFields] = [
                .createdAt,
                .description,
                .entities,
                .id,
                .location,
                .name,
                .pinnedTweetID,
                .profileImageURL,
                .protected,
                .publicMetrics,
                .url,
                .username,
                .verified,
                .withheld
            ]
            return [
                expansions.queryItem,
                tweetsFields.queryItem,
                userFields.queryItem,
                URLQueryItem(name: "usernames", value: usernames),
            ]
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
}

extension Twitter.API.V2.UserLookup {
    public struct Content: Codable {
        public let data: [Twitter.Entity.V2.User]?
        public let errors: [Twitter.Response.V2.ContentError]?
    }
}
