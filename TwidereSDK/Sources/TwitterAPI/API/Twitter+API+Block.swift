//
//  Twitter+API+Block.swift
//  
//
//  Created by Cirno MainasuK on 2021-1-13.
//

import Foundation
import Combine

extension Twitter.API.Block {
    
    static let createEndpointURL = Twitter.API.endpointURL.appendingPathComponent("blocks/create.json")
    static let destroyEndpointURL = Twitter.API.endpointURL.appendingPathComponent("blocks/destroy.json")
    
    public static func block(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: BlockUpdateQuery) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        let url: URL = {
            switch query.queryKind {
            case .create: return createEndpointURL
            case .destroy: return destroyEndpointURL
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

extension Twitter.API.Block {
    
    public struct BlockUpdateQuery {
        public let userID: Twitter.Entity.User.ID
        public let queryKind: QueryKind
        
        public enum QueryKind {
            case create
            case destroy
        }
        
        public init(userID: Twitter.Entity.User.ID, queryKind: Twitter.API.Block.BlockUpdateQuery.QueryKind) {
            self.userID = userID
            self.queryKind = queryKind
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "user_id", value: userID))
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
}
