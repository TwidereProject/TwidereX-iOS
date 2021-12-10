//
//  Mastodon+API+Poll.swift
//  
//
//  Created by MainasuK on 2021-12-10.
//

import Foundation

extension Mastodon.API.Poll {
    
    static func viewPollEndpointURL(domain: String, pollID: Mastodon.Entity.Poll.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("polls")
            .appendingPathComponent(pollID)
    }
 
    /// View a poll
    ///
    /// Using this endpoint to view the poll of status
    ///
    /// - Since: 2.8.0
    /// - Version: 3.4.2
    /// # Last Update
    ///   2021/12/10
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/polls/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - pollID: id for poll
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `Poll` nested in the response
    public static func poll(
        session: URLSession,
        domain: String,
        pollID: Mastodon.Entity.Poll.ID,
        authorization: Mastodon.API.OAuth.Authorization?
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Poll> {
        let request = Mastodon.API.request(
            url: viewPollEndpointURL(domain: domain, pollID: pollID),
            method: .GET,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Poll.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
}

extension Mastodon.API.Poll {
    
    static func votePollEndpointURL(domain: String, pollID: Mastodon.Entity.Poll.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("polls")
            .appendingPathComponent(pollID)
            .appendingPathComponent("votes")
    }
    
    /// Vote on a poll
    ///
    /// Using this endpoint to vote an option of poll
    ///
    /// - Since: 2.8.0
    /// - Version: 3.4.2
    /// # Last Update
    ///   2021/12/10
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/polls/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - pollID: id for poll
    ///   - query: `VoteQuery`
    ///   - authorization: User token
    /// - Returns: `Poll` nested in the response
    public static func vote(
        session: URLSession,
        domain: String,
        pollID: Mastodon.Entity.Poll.ID,
        query: VoteQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Poll> {
        let request = Mastodon.API.request(
            url: votePollEndpointURL(domain: domain, pollID: pollID),
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Poll.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    

    public struct VoteQuery: JSONEncodeQuery {
        
        public let choices: [Int]
        
        public init(choices: [Int]) {
            self.choices = choices
        }
        
        var queryItems: [URLQueryItem]? { nil }
    }
}
