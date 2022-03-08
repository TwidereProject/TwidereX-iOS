//
//  Mastodon+API+List.swift
//  
//
//  Created by MainasuK on 2022-3-8.
//

import Foundation

extension Mastodon.API.List {
    
    static func listsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("lists")
    }
    
    /// Fetch all lists that the user owns.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.2
    /// # Last Update
    ///   2022/3/8
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/timelines/lists/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token
    /// - Returns: `[Mastodon.Entity.List]` nested in the response
    public static func ownedLists(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.List]> {
        let request = Mastodon.API.request(
            url: listsEndpointURL(domain: domain),
            method: .GET,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.List].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
}
