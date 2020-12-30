//
//  Twitter+API+V2+FollowLookup.swift
//  
//
//  Created by Cirno MainasuK on 2020-12-22.
//

import os.log
import Foundation
import Combine

extension Twitter.API.V2.FollowLookup {
    
    static func followingEndpointURL(userID: Twitter.Entity.V2.User.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(userID)
            .appendingPathComponent("following")
    }
    
    static func followersEndpointURL(userID: Twitter.Entity.V2.User.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("users")
            .appendingPathComponent(userID)
            .appendingPathComponent("followers")
    }
    
    public static func following(
        session: URLSession,
        authorization: Twitter.API.OAuth.Authorization,
        query: Twitter.API.V2.FollowLookup.Query
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.FollowLookup.Content>, Error> {
        guard var components = URLComponents(string: followingEndpointURL(userID: query.userID).absoluteString) else { fatalError() }
        
        // not query pinned tweet expansion to save API useage
        components.queryItems = [
            Twitter.Request.tweetsFields.queryItem,
            Twitter.Request.userFields.queryItem,
            URLQueryItem(name: "max_results", value: String(query.maxResults)),
        ]
        query.paginationToken.flatMap { components.queryItems?.append(URLQueryItem(name: "pagination_token", value: $0)) }
        
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
                    let value = try Twitter.API.decode(type: Twitter.API.V2.FollowLookup.Content.self, from: data, response: response)
                    return Twitter.Response.Content(value: value, response: response)
                } catch {
                    debugPrint(error)
                    os_log("%{public}s[%{public}ld], %{public}s: decode fail. error: %s. data: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription, String(data: data, encoding: .utf8) ?? "<nil>")
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }
    
    public static func followers(
        session: URLSession,
        authorization: Twitter.API.OAuth.Authorization,
        query: Twitter.API.V2.FollowLookup.Query
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.FollowLookup.Content>, Error> {
        guard var components = URLComponents(string: followersEndpointURL(userID: query.userID).absoluteString) else { fatalError() }
        
        // not query pinned tweet expansion to save API useage
        components.queryItems = [
            Twitter.Request.tweetsFields.queryItem,
            Twitter.Request.userFields.queryItem,
            URLQueryItem(name: "max_results", value: String(query.maxResults)),
        ]
        query.paginationToken.flatMap { components.queryItems?.append(URLQueryItem(name: "pagination_token", value: $0)) }
        
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
                    let value = try Twitter.API.decode(type: Twitter.API.V2.FollowLookup.Content.self, from: data, response: response)
                    return Twitter.Response.Content(value: value, response: response)
                } catch {
                    debugPrint(error)
                    os_log("%{public}s[%{public}ld], %{public}s: decode fail. error: %s. data: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription, String(data: data, encoding: .utf8) ?? "<nil>")
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }

}

extension Twitter.API.V2.FollowLookup {
    
    public struct Query {
        public let userID: Twitter.Entity.V2.User.ID
        public let maxResults: Int
        public let paginationToken: String?
        
        public init(userID: Twitter.Entity.V2.User.ID, maxResults: Int, paginationToken: String?) {
            self.userID = userID
            self.maxResults = min(1000, max(10, maxResults))
            self.paginationToken = paginationToken
        }
    }
    
    public struct Content: Codable {
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
