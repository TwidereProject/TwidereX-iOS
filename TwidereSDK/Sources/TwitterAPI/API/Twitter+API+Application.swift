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
    
    public static func rateLimitStatus(session: URLSession, authorization: Twitter.API.OAuth.Authorization) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.RateLimitStatus>, Error> {
        let request = Twitter.API.request(url: rateLimitStatusEndpointURL, httpMethod: "GET", authorization: authorization, queryItems: nil)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                do {
                    let value = try Twitter.API.decode(type: Twitter.Entity.RateLimitStatus.self, from: data, response: response)
                    return Twitter.Response.Content(value: value, response: response)
                } catch {
                    debugPrint(error)
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }
    
}
