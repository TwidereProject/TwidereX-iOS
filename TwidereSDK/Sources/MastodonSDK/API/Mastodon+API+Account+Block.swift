//
//  Mastodon+API+Account+Block.swift
//  
//
//  Created by Cirno MainasuK on 2021-10-21.
//

import Foundation

extension Mastodon.API.Account {
    
    static func blockEndpointURL(domain: String, accountID: Mastodon.Entity.Account.ID) -> URL {
        let pathComponent = "accounts/" + accountID + "/block"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Block
    ///
    /// Block the given account. Clients should filter statuses from this account if received (e.g. due to a boost in the Home timeline).
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.1
    /// # Last Update
    ///   2021/10/21
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - accountID: id for account
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Relationship` nested in the response
    public static func block(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let request = Mastodon.API.request(
            url: blockEndpointURL(domain: domain, accountID: accountID),
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
    
    static func unblockEndpointURL(domain: String, accountID: Mastodon.Entity.Account.ID) -> URL {
        let pathComponent = "accounts/" + accountID + "/unblock"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }
    
    /// Unblock
    ///
    /// Unblock the given account.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.1
    /// # Last Update
    ///   2021/10/21
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - accountID: id for account
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Relationship` nested in the response
    public static func unblock(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let request = Mastodon.API.request(
            url: unblockEndpointURL(domain: domain, accountID: accountID),
            method: .POST,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Relationship.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
}
