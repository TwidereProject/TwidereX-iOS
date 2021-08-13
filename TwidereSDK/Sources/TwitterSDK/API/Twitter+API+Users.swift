//
//  Twitter+API+Users.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-30.
//

import Foundation
import Combine

extension Twitter.API.Users {
    
    static let searchEndpointURL = Twitter.API.endpointURL.appendingPathComponent("users/search.json")
    static let reportSpamEndpointURL = Twitter.API.endpointURL.appendingPathComponent("users/report_spam.json")
    
    public static func search(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: SearchQuery) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.User]>, Error> {
        let request = Twitter.API.request(url: searchEndpointURL, httpMethod: "GET", authorization: authorization, queryItems: query.queryItems)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: [Twitter.Entity.User].self, from: data, response: response)
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func reportSpam(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: ReportSpamQuery) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        var request = Twitter.API.request(url: reportSpamEndpointURL, httpMethod: "POST", authorization: authorization, queryItems: query.queryItems)
        request.httpMethod = "POST"
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: Twitter.Entity.User.self, from: data, response: response)
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Twitter.API.Users {
    
    public struct SearchQuery {
        public let q: String
        public let page: Int
        public let count: Int
        
        public init(q: String, page: Int, count: Int) {
            self.q = q
            self.page = page
            self.count = count
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "q", value: q))
            items.append(URLQueryItem(name: "page", value: "\(page)"))
            items.append(URLQueryItem(name: "count", value: "\(count)"))
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
    public struct ReportSpamQuery {
        public let userID: Twitter.Entity.User.ID
        public let performBlock: Bool
        
        public init(userID: Twitter.Entity.User.ID, performBlock: Bool) {
            self.userID = userID
            self.performBlock = performBlock
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "user_id", value: userID))
            items.append(URLQueryItem(name: "perform_block", value: performBlock ? "true" : "false"))
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
}

