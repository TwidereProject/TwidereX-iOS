//
//  Twitter+API+Users.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-30.
//

import Foundation
import Combine

extension Twitter.API.Users {
    
    static let reportSpamEndpointURL = Twitter.API.endpointURL.appendingPathComponent("users/report_spam.json")
    
    public static func reportSpam(
        session: URLSession,
        query: ReportSpamQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.Entity.User> {
        let request = Twitter.API.request(
            url: reportSpamEndpointURL,
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.Entity.User.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct ReportSpamQuery: Query {
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
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
}

