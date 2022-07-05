//
//  Mastodon+API+Account+FollowRequest.swift
//  
//
//  Created by MainasuK on 2022-7-1.
//

import Foundation

// MARK: - Follow Request
extension Mastodon.API.Account {
    
    private static func acceptFollowRequestEndpointURL(domain: String, userID: Mastodon.Entity.Account.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("follow_requests")
            .appendingPathComponent(userID)
            .appendingPathComponent("authorize")
    }

    /// Accept Follow
    ///
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/follow_requests/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - userID: ID of the account in the database
    ///   - authorization: User token
    /// - Returns: `Relationship` nested in the response
    public static func acceptFollowRequest(
        session: URLSession,
        domain: String,
        userID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let request = Mastodon.API.request(
            url: acceptFollowRequestEndpointURL(domain: domain, userID: userID),
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
    
    private static func rejectFollowRequestEndpointURL(domain: String, userID: Mastodon.Entity.Account.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("follow_requests")
            .appendingPathComponent(userID)
            .appendingPathComponent("reject")
    }
    
    /// Reject Follow
    ///
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/follow_requests/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - userID: ID of the account in the database
    ///   - authorization: User token
    /// - Returns: `Relationship` nested in the response
    public static func rejectFollowRequest(
        session: URLSession,
        domain: String,
        userID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let request = Mastodon.API.request(
            url: rejectFollowRequestEndpointURL(domain: domain, userID: userID),
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
 
    public enum FollowReqeustQuery {
        case accept
        case reject
    }
    
    public static func followRequest(
        session: URLSession,
        domain: String,
        userID: Mastodon.Entity.Account.ID,
        query: FollowReqeustQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        switch query {
        case .accept:
            return try await acceptFollowRequest(
                session: session,
                domain: domain,
                userID: userID,
                authorization: authorization
            )
        case .reject:
            return try await rejectFollowRequest(
                session: session,
                domain: domain,
                userID: userID,
                authorization: authorization
            )
        }   // end switch
    }   // end func
    
}
