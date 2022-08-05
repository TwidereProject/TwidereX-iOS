//
//  Twitter+API+DirectMessage.swift
//  
//
//  Created by MainasuK on 2022-8-5.
//

import Foundation

extension Twitter.API {
    public enum DirectMessage { }
}

extension Twitter.API.DirectMessage {
    
    private static var eventsListEndpoint: URL {
        return Twitter.API.endpointURL
            .appendingPathComponent("direct_messages")
            .appendingPathComponent("events")
            .appendingPathComponent("list")
            .appendingPathExtension("json")
    }
    
    public static func events(
        session: URLSession,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<EventsContent> {
        let request = Twitter.API.request(
            url: eventsListEndpoint,
            method: .GET,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: EventsContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct EventsContent: Codable {
        public let nextCursor: String?
        
        enum CodingKeys: String, CodingKey {
            case nextCursor = "next_cursor"
        }
    }
    
}
