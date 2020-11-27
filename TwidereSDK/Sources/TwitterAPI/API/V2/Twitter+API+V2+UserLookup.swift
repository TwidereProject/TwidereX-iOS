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
    static let usersByEndpointURL = Twitter.API.endpointV2URL.appendingPathComponent("users/by")
    
    public static func users(userIDs: [Twitter.Entity.User.ID], session: URLSession, authorization: Twitter.API.OAuth.Authorization) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.UserLookup.Content>, Error> {
        guard var components = URLComponents(string: usersEndpointURL.absoluteString) else { fatalError() }
        
        let ids = userIDs.joined(separator: ",")
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
        components.queryItems = [
            expansions.queryItem,
            tweetsFields.queryItem,
            userFields.queryItem,
            URLQueryItem(name: "ids", value: ids),
        ]
        
        guard let requestURL = components.url else { fatalError() }
        var request = URLRequest(
            url: requestURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: Twitter.API.timeoutInterval
        )
        request.setValue(
            authorization.authorizationHeader(requestURL: requestURL, httpMethod: "GET"),
            forHTTPHeaderField: Twitter.API.OAuth.authorizationField
        )
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: Twitter.API.V2.UserLookup.Content.self, from: data, response: response)
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func users(usernames: [String], session: URLSession, authorization: Twitter.API.OAuth.Authorization) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.UserLookup.Content>, Error> {
        guard var components = URLComponents(string: usersByEndpointURL.absoluteString) else { fatalError() }
        
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
        components.queryItems = [
            expansions.queryItem,
            tweetsFields.queryItem,
            userFields.queryItem,
            URLQueryItem(name: "usernames", value: usernames),
        ]
        
        guard let requestURL = components.url else { fatalError() }
        var request = URLRequest(
            url: requestURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: Twitter.API.timeoutInterval
        )
        request.setValue(
            authorization.authorizationHeader(requestURL: requestURL, httpMethod: "GET"),
            forHTTPHeaderField: Twitter.API.OAuth.authorizationField
        )
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: Twitter.API.V2.UserLookup.Content.self, from: data, response: response)
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Twitter.API.V2.UserLookup {
    public struct Content: Codable {
        public let data: [Twitter.Entity.V2.User]?
    }
}
