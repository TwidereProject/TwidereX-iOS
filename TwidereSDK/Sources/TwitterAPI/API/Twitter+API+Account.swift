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

    public static func verifyCredentials(session: URLSession, authorization: Twitter.API.OAuth.Authorization) -> AnyPublisher<Twitter.Response<Twitter.Entity.User>, Error> {
        let request = Twitter.API.request(url: verifyCredentialsEndpointURL, httpMethod: "GET", authorization: authorization, queryItems: nil)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: Twitter.Entity.User.self, from: data, response: response)
                return Twitter.Response(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}
