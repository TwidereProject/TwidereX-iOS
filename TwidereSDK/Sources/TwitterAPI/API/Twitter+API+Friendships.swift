//
//  File.swift
//  
//
//  Created by Cirno MainasuK on 2020-11-2.
//

import Foundation
import Combine

extension Twitter.API.Friendships {
    
    static let createEndpointURL = Twitter.API.endpointURL.appendingPathComponent("friendships/create.json")
    static let destroyEndpointURL = Twitter.API.endpointURL.appendingPathComponent("friendships/destroy.json")
    static let updateEndpointURL = Twitter.API.endpointURL.appendingPathComponent("friendships/update.json")
    
    public static func friendships(session: URLSession, authorization: Twitter.API.OAuth.Authorization, queryKind: QueryType, query: Query) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        let url: URL = {
            switch queryKind {
            case .create: return createEndpointURL
            case .destroy: return destroyEndpointURL
            case .update: return updateEndpointURL
            }
        }()
        var request = Twitter.API.request(url: url, httpMethod: "POST", authorization: authorization, queryItems: query.queryItems)
        request.httpMethod = "POST"
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: Twitter.Entity.User.self, from: data, response: response)
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Twitter.API.Friendships {
    
    public enum QueryType {
        case create
        case destroy
        case update
    }
    
    public struct Query {
        public let userID: Twitter.Entity.User.ID
        
        public init(userID: Twitter.Entity.User.ID) {
            self.userID = userID
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "user_id", value: userID))
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
}
