//
//  Twitter+API+Account.swift
//  
//
//  Created by Cirno MainasuK on 2020-9-28.
//

import Foundation
import Combine

extension Twitter.API.Account {
    
    static let verifyCredentialsEndpointURL = Twitter.API.endpointURL.appendingPathComponent("account/verify_credentials.json")

    public static func verifyCredentials(
        session: URLSession,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.Entity.User> {
        let request = Twitter.API.request(
            url: verifyCredentialsEndpointURL,
            httpMethod: "GET",
            authorization: authorization,
            queryItems: nil
        )

        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.Entity.User.self, from: data, response: response)
        
        return Twitter.Response.Content(value: value, response: response)
    }
    
}
