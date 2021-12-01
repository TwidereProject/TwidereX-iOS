//
//  Mastodon+API+Status.swift
//  Mastodon+API+Status
//
//  Created by Cirno MainasuK on 2021-9-6.
//

import Foundation

extension Mastodon.API.Status {
    
    static func publishStatusEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("statuses")
    }
    
    /// Publish new status
    ///
    /// Post a new status.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.2
    /// # Last Update
    ///   2021/12/1
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `PublishStatusQuery`
    ///   - authorization: User token
    /// - Returns: `Mastodon.Entity.Status`
    public static func publish(
        session: URLSession,
        domain: String,
        idempotencyKey: String?,
        query: PublishStatusQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        var request = Mastodon.API.request(
            url: publishStatusEndpointURL(domain: domain),
            method: .POST,
            query: query,
            authorization: authorization
        )
        if let idempotencyKey = idempotencyKey {
            request.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
        }
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Status.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public struct PublishStatusQuery: JSONEncodeQuery {
        
        public let status: String?
        public let mediaIDs: [String]?
        public let pollOptions: [String]?
        public let pollExpiresIn: Int?
        public let pollMultiple: Bool?
        public let inReplyToID: Mastodon.Entity.Status.ID?
        public let sensitive: Bool?
        public let spoilerText: String?
        public let visibility: Mastodon.Entity.Status.Visibility?
        
        public init(
            status: String?,
            mediaIDs: [String]?,
            pollOptions: [String]?,
            pollExpiresIn: Int?,
            pollMultiple: Bool?,
            inReplyToID: Mastodon.Entity.Status.ID?,
            sensitive: Bool?,
            spoilerText: String?,
            visibility: Mastodon.Entity.Status.Visibility?
        ) {
            self.status = status
            self.mediaIDs = mediaIDs
            self.pollOptions = pollOptions
            self.pollExpiresIn = pollExpiresIn
            self.pollMultiple = pollMultiple
            self.inReplyToID = inReplyToID
            self.sensitive = sensitive
            self.spoilerText = spoilerText
            self.visibility = visibility
        }
        
        var contentType: String? {
            return Self.multipartContentType()
        }
        var queryItems: [URLQueryItem]? { nil }
        var body: Data? {
            var data = Data()

            status.flatMap { data.append(Data.multipart(key: "status", value: $0)) }
            for mediaID in mediaIDs ?? [] {
                data.append(Data.multipart(key: "media_ids[]", value: mediaID))
            }
            for pollOption in pollOptions ?? [] {
                data.append(Data.multipart(key: "poll[options][]", value: pollOption))
            }
            pollExpiresIn.flatMap { data.append(Data.multipart(key: "poll[expires_in]", value: $0)) }
            pollMultiple.flatMap { data.append(Data.multipart(key: "poll[multiple]", value: $0)) }
            inReplyToID.flatMap { data.append(Data.multipart(key: "in_reply_to_id", value: $0)) }
            sensitive.flatMap { data.append(Data.multipart(key: "sensitive", value: $0)) }
            spoilerText.flatMap { data.append(Data.multipart(key: "spoiler_text", value: $0)) }
            visibility.flatMap { data.append(Data.multipart(key: "visibility", value: $0.rawValue)) }

            data.append(Data.multipartEnd())
            return data
        }
    }
}

extension Mastodon.API.Status {
    
    static func statusContextEndpointURL(domain: String, statusID: Mastodon.Entity.Status.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("statuses/\(statusID)/context")
    }
    
    /// Parent and child statuses
    ///
    /// View statuses above and below this status in the thread.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.2
    /// # Last Update
    ///   2021/12/1
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - statusID: id of status
    ///   - authorization: User token. Optional for public statuses
    /// - Returns: `Mastodon.Entity.Context`
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


