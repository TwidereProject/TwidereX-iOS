//
//  Twitter+API+Application.swift
//  
//
//  Created by Cirno MainasuK on 2020-12-7.
//

import Foundation
import Combine

extension Twitter.API.Application {
    
    static let rateLimitStatusEndpointURL = Twitter.API.endpointURL.appendingPathComponent("application/rate_limit_status.json")
    
    public static func rateLimitStatus(
        session: URLSession,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.Entity.RateLimitStatus> {
        let request = Twitter.API.request(
            url: rateLimitStatusEndpointURL,
            method: .GET,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.Entity.RateLimitStatus.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
}
