//
//  Mastodon+API+Status.swift
//  Mastodon+API+Status
//
//  Created by Cirno MainasuK on 2021-9-6.
//

import Foundation

extension Mastodon.API.Status {
    
    static func statusContextEndpointURL(domain: String, statusID: Mastodon.Entity.Status.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("statuses/\(statusID)/context")
    }
    
    public static func context(
        session: URLSession,
        domain: String,
        statusID: Mastodon.Entity.Status.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Context> {
        let request = Mastodon.API.request(
            url: statusContextEndpointURL(domain: domain, statusID: statusID),
            method: .GET,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Context.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
}
