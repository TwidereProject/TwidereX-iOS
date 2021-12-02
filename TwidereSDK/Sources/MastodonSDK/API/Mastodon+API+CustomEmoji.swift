//
//  Mastodon+API+CustomEmoji.swift
//  
//
//  Created by MainasuK on 2021-11-24.
//

import Foundation

extension Mastodon.API.CustomEmoji {
    
    static func customEmojisEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("custom_emojis")
    }

    /// Custom emoji
    ///
    /// Returns custom emojis that are available on the server.
    ///
    /// - Since: 2.0.0
    /// - Version: 3.4.2
    /// # Last Update
    ///   2021/11/24
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/instance/custom_emojis/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    /// - Returns: `AnyPublisher` contains [`Emoji`] nested in the response
    public static func emojis(
        session: URLSession,
        domain: String
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Emoji]> {
        let request = Mastodon.API.request(
            url: customEmojisEndpointURL(domain: domain),
            method: .GET,
            query: nil,
            authorization: nil
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.Emoji].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
}
