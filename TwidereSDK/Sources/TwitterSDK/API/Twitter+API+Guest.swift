//
//  Twitter+API+Guest.swift
//  
//
//  Created by MainasuK on 2022-8-22.
//

import Foundation

extension Twitter.API {
    public enum Guest { }
}

extension Twitter.API.Guest {
    public struct GuestAuthorization: Hashable {
        public static var userAgent: String {
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Safari/605.1.15"
        }

        public static var authorization: String {
            "Bearer AAAAAAAAAAAAAAAAAAAAAPYXBAAAAAAACLXUNDekMxqa8h%2F40K4moUkGsoc%3DTYfbDKbT3jJPCEVnMYqilB28NHfOPqkca3qaAxGfsyKCs0wRbw"
        }
        
        
        public let userAgent: String
        public let authorization: String
        public let token: String
        
        public init(
            userAgent: String = GuestAuthorization.userAgent,
            authorization: String = GuestAuthorization.authorization,
            token: String
        ) {
            self.userAgent = userAgent
            self.authorization = authorization
            self.token = token
        }
    }
}

extension Twitter.API.Guest {
    
    private static var activeEndpoint: URL {
        Twitter.API.endpointURL
            .appendingPathComponent("guest")
            .appendingPathComponent("activate")
            .appendingPathExtension("json")
    }
    
    public static func active(
        session: URLSession
    ) async throws -> Twitter.Response.Content<ActiveContent> {
        var request = URLRequest(
            url: activeEndpoint,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: Twitter.API.timeoutInterval
        )
        request.httpMethod = "POST"
        request.setValue(GuestAuthorization.authorization, forHTTPHeaderField: "Authorization")
        request.setValue(GuestAuthorization.userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: ActiveContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct ActiveContent: Codable {
        public let guestToken: String
        
        enum CodingKeys: String, CodingKey {
            case guestToken = "guest_token"
        }
    }
    
}
