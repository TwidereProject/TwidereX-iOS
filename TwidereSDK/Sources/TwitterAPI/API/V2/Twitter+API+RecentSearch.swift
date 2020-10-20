//
//  Twitter+API+RecentSearch.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-16.
//

import os.log
import Foundation
import Combine

extension Twitter.API.RecentSearch {
    
    static let tweetsSearchRecentEndpointURL = Twitter.API.endpointV2URL.appendingPathComponent("tweets/search/recent")
    
    public static func tweetsSearchRecent(query: String, maxResults: Int, session: URLSession, authorization: Twitter.API.OAuth.Authorization) -> AnyPublisher<Twitter.Response.Content<Twitter.API.RecentSearch.Content>, Error> {
        guard var components = URLComponents(string: tweetsSearchRecentEndpointURL.absoluteString) else { fatalError() }
        
        let expansions: [Twitter.Request.Expansions] = [
            .attachmentsPollIDs,
            .attachmentsMediaKeys,
            .authorID,
            .entitiesMentionsUsername,
            .geoPlaceID,
            .inReplyToUserID,
            .referencedTweetsID,
            .referencedTweetsIDAuthorID
        ]
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
            URLQueryItem(name: "max_results", value: String(min(100, max(10, maxResults)))),
        ]
        components.percentEncodedQueryItems = (components.percentEncodedQueryItems ?? []) + [URLQueryItem(name: "query", value: query.urlEncoded)]
        
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
                do {
                    let value = try Twitter.API.decode(type: Twitter.API.RecentSearch.Content.self, from: data, response: response)
                    return Twitter.Response.Content(value: value, response: response)
                } catch {
                    os_log("%{public}s[%{public}ld], %{public}s: decode fail. data: %s", ((#file as NSString).lastPathComponent), #line, #function, String(data: data, encoding: .utf8) ?? "<nil>")

                    throw error
                }
            }
            .eraseToAnyPublisher()
    }

}

extension Twitter.API.RecentSearch {
    public struct Content: Codable {
        public let data: [Twitter.Entity.V2.Tweet]?
        public let includes: Include?
        public let meta: Meta
        
        public struct Include: Codable {
            public let users: [Twitter.Entity.V2.User]?
            public let tweets: [Twitter.Entity.V2.Tweet]?
            // public let media: [Twitter.Entity.UserV2]?
        }
        
        public struct Meta: Codable {
            public let newestID: String?
            public let oldestID: String?
            public let resultCount: Int
            public let nextToken: String?
            
            public enum CodingKeys: String, CodingKey {
                case newestID = "newest_id"
                case oldestID = "oldest_id"
                case resultCount = "result_count"
                case nextToken = "next_token"
                
            }
        }
    }
}
