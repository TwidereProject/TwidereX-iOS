//
//  Mastodon+API+V2+Media.swift
//  
//
//  Created by MainasuK on 2021-11-26.
//

import Foundation

extension Mastodon.API.V2.Media {
    static func uploadMediaEndpointURL(domain: String) -> URL {
        Mastodon.API.endpointV2URL(domain: domain).appendingPathComponent("media")
    }

    /// Upload media as attachment
    ///
    /// Creates an attachment to be used with a new status.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.2
    /// # Last Update
    ///   2021/11/26
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/media/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `UploadMediaQuery`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Attachment` nested in the response
    public static func uploadMedia(
        session: URLSession,
        domain: String,
        query: Mastodon.API.Media.UploadMediaQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Attachment> {
        var request = Mastodon.API.request(
            url: uploadMediaEndpointURL(domain: domain),
            method: .POST,
            query: query,
            authorization: authorization
        )
        request.timeoutInterval = 180    // should > 200 Kb/s for 40 MiB media attachment
        let serialStream = query.serialStream
        defer {
            serialStream.boundStreams.output.close()
        }
        request.httpBodyStream = serialStream.boundStreams.input
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Attachment.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
}
