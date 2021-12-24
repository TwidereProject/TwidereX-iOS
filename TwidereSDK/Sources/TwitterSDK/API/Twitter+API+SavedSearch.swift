//
//  Twitter+API+SavedSearch.swift
//  
//
//  Created by MainasuK on 2021-12-22.
//

import Foundation

extension Twitter.API.SavedSearch {
    
    static let listEndpointURL = Twitter.API.endpointURL
        .appendingPathComponent("saved_searches")
        .appendingPathComponent("list.json")
    
    // Returns the authenticated user's saved search queries.
    // doc: https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/get-saved_searches-list
    public static func list(
        session: URLSession,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.SavedSearch]> {
        let request = Twitter.API.request(
            url: listEndpointURL,
            method: .GET,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: [Twitter.Entity.SavedSearch].self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }

}

extension Twitter.API.SavedSearch {
    
    static let createEndpointURL = Twitter.API.endpointURL
        .appendingPathComponent("saved_searches")
        .appendingPathComponent("create.json")
    
    // Create a new saved search for the authenticated user. A user may only have 25 saved searches.
    // doc: https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/post-saved_searches-create
    public static func create(
        session: URLSession,
        query: CreateQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.Entity.SavedSearch> {
        let request = Twitter.API.request(
            url: listEndpointURL,
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.Entity.SavedSearch.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }

    public struct CreateQuery: Query {
        public let query: String
        
        public init(query: String) {
            self.query = query
        }
        
        var queryItems: [URLQueryItem]? {
            [URLQueryItem(name: "query", value: query)]
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
}

extension Twitter.API.SavedSearch {
    
    static func destroyEndpointURL(id: Twitter.Entity.SavedSearch.ID) -> URL {
        Twitter.API.endpointURL
            .appendingPathComponent("saved_searches")
            .appendingPathComponent("destroy")
            .appendingPathComponent("\(id).json")
    }
    
    // Destroys a saved search for the authenticating user. The authenticating user must be the owner of saved search id being destroyed.
    // doc: https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/post-saved_searches-destroy-id
    public static func destroy(
        session: URLSession,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<Twitter.Entity.SavedSearch> {
        let request = Twitter.API.request(
            url: listEndpointURL,
            method: .POST,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.Entity.SavedSearch.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }

}
