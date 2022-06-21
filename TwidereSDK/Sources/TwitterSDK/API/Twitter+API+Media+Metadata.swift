//
//  Twitter+API+Media+Metadata.swift
//  
//
//  Created by MainasuK on 2022-6-1.
//

import Foundation
import Combine

extension Twitter.API.Media {
    public enum Metadata { }
}

extension Twitter.API.Media.Metadata {
    
    private static var createEndpointURL: URL {
        Twitter.API.uploadEndpointURL
            .appendingPathComponent("media")
            .appendingPathComponent("metadata")
            .appendingPathComponent("create.json")
    }
    
    public static func create(
        session: URLSession,
        query: CreateQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<CreateResponse> {
        let request = Twitter.API.request(
            url: createEndpointURL,
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        guard data.isEmpty else {
            let value = try Twitter.API.decode(type: CreateResponse.self, from: data, response: response)
            return Twitter.Response.Content(value: value, response: response)
        }
        return Twitter.Response.Content(value: .init(), response: response)
    }
    
    public struct CreateQuery: JSONEncodeQuery {
        public let mediaID: String
        public let altText: AltText
        
        public enum CodingKeys: String, CodingKey {
            case mediaID = "media_id"
            case altText = "alt_text"
        }
        
        public init(
            mediaID: String,
            altText: String
        ) {
            self.mediaID = mediaID
            self.altText = .init(text: altText)
        }
        
        public struct AltText: Codable {
            public let text: String
        }
        
        var queryItems: [URLQueryItem]? { nil }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
    }
    
    public struct CreateResponse: Codable { }
    
}
