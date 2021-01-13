//
//  Twitter+API+Mute.swift
//  
//
//  Created by Cirno MainasuK on 2021-1-13.
//

import Foundation
import Combine

extension Twitter.API.Mute {
    
    static let createEndpointURL = Twitter.API.endpointURL.appendingPathComponent("mutes/users/create.json")
    static let destroyEndpointURL = Twitter.API.endpointURL.appendingPathComponent("mutes/users/destroy.json")
    
    public static func mute(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: MuteUpdateQuery) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
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

extension Twitter.API.Mute {

    public struct MuteUpdateQuery {
        public let userID: Twitter.Entity.User.ID
        public let queryKind: QueryKind
        
        public enum QueryKind {
            case create
            case destroy
        }
        
        public init(userID: Twitter.Entity.User.ID, queryKind: Twitter.API.Mute.MuteUpdateQuery.QueryKind) {
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
