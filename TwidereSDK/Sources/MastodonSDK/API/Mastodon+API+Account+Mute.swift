//
//  Mastodon+API+Account+Mute.swift
//  
//
//  Created by MainasuK on 2021-12-6.
//

import Foundation

extension Mastodon.API.Account {
 
    static func muteEndpointURL(domain: String, accountID: Mastodon.Entity.Account.ID) -> URL {
        let pathComponent = "accounts/" + accountID + "/mute"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Mute
    ///
    /// Mute the given account. Clients should filter statuses and notifications from this account, if received (e.g. due to a boost in the Home timeline).
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.2
    /// # Last Update
    ///   2021/12/6
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - accountID: id for account
    ///   - authorization: User token.
    /// - Returns: `Relationship` nested in the response
    public static func mute(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let request = Mastodon.API.request(
            url: muteEndpointURL(domain: domain, accountID: accountID),
            method: .POST,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Relationship.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
}

extension Mastodon.API.Account {
 
    static func unmuteEndpointURL(domain: String, accountID: Mastodon.Entity.Account.ID) -> URL {
        let pathComponent = "accounts/" + accountID + "/unmute"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Unmute
    ///
    /// Unmute the given account.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.2
    /// # Last Update
    ///   2021/12/6
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - accountID: id for account
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Relationship` nested in the response
    public static func unmute(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let request = Mastodon.API.request(
            url: unmuteEndpointURL(domain: domain, accountID: accountID),
            method: .POST,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Relationship.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
}
