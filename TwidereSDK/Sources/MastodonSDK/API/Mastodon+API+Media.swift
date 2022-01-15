//
//  Mastodon+API+Media.swift
//  
//
//  Created by MainasuK on 2021-11-26.
//

import Foundation

extension Mastodon.API.Media {
    
    static func uploadMediaEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("media")
    }
    
    /// Upload media as attachment
    ///
    /// Creates an attachment to be used with a new status.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
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
        query: UploadMediaQuery,
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
        
        // total unit count in bytes count
        // will small than actally count due to multipart protocol meta
        serialStream.progress.totalUnitCount = {
            var size = 0
            size += query.file?.sizeInByte ?? 0
            size += query.thumbnail?.sizeInByte ?? 0
            return Int64(size)
        }()
        query.progress.addChild(
            serialStream.progress,
            withPendingUnitCount: query.progress.totalUnitCount
        )
        
        defer {
            // close stream when task finish
            serialStream.boundStreams.output.close()
        }
        request.httpBodyStream = serialStream.boundStreams.input
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Attachment.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public struct UploadMediaQuery: Query {
        public let file: Mastodon.API.MediaAttachment?
        public let thumbnail: Mastodon.API.MediaAttachment?
        public let description: String?
        public let focus: String?
        
        public let progress: Progress = {
            let progress = Progress()
            progress.totalUnitCount = 100
            return progress
        }()
        
        public init(
            file: Mastodon.API.MediaAttachment?,
            thumbnail: Mastodon.API.MediaAttachment?,
            description: String?,
            focus: String?
        ) {
            self.file = file
            self.thumbnail = thumbnail
            self.description = description
            self.focus = focus
        }
        
        var queryItems: [URLQueryItem]? { nil }
        
        var contentType: String? {
            return Self.multipartContentType()
        }
        
        var body: Data? {
            // using stream data
            return nil
        }
        
        var serialStream: SerialStream {
            var streams: [InputStream] = []
            
            file.flatMap { value in
                streams.append(InputStream(data: Data.multipart(key: "file", value: value)))
                value.multipartStreamValue.flatMap { streams.append($0) }
            }
            thumbnail.flatMap { value in
                streams.append(InputStream(data: Data.multipart(key: "thumbnail", value: value)))
                value.multipartStreamValue.flatMap { streams.append($0) }
            }
            description.flatMap { value in
                streams.append(InputStream(data: Data.multipart(key: "description", value: value)))
            }
            focus.flatMap { value in
                streams.append(InputStream(data: Data.multipart(key: "focus", value: value)))
            }
            streams.append(InputStream(data: Data.multipartEnd()))
            
            return SerialStream(streams: streams)
        }

        public var clone: UploadMediaQuery {
            UploadMediaQuery(file: file, thumbnail: thumbnail, description: description, focus: focus)
        }
    }

    
}

extension Mastodon.API.Media {
    
    static func getMediaEndpointURL(
        domain: String,
        attachmentID: Mastodon.Entity.Attachment.ID
    ) -> URL {
        Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("media")
            .appendingPathComponent(attachmentID)
    }
    
    /// Get media attachment
    ///
    /// Get an Attachment, before it is attached to a status and posted, but after it is accepted for processing.
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
    ///   - mediaID: The ID of attachment
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Attachment` nested in the response
    public static func getMedia(
        session: URLSession,
        domain: String,
        attachmentID: Mastodon.Entity.Attachment.ID,
        authorization: Mastodon.API.OAuth.Authorization?
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Attachment> {
        var request = Mastodon.API.request(
            url: getMediaEndpointURL(domain: domain, attachmentID: attachmentID),
            method: .GET,
            query: nil,
            authorization: authorization
        )
        request.timeoutInterval = 10    // short timeout for quick retry
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Attachment.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
}

extension Mastodon.API.Media {

    static func updateMediaEndpointURL(
        domain: String,
        attachmentID: Mastodon.Entity.Attachment.ID
    ) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("media")
            .appendingPathComponent(attachmentID)
    }
    
    /// Update attachment
    ///
    /// Update an Attachment, before it is attached to a status and posted..
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
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
    public static func updateMedia(
        session: URLSession,
        domain: String,
        attachmentID: Mastodon.Entity.Attachment.ID,
        query: UpdateMediaQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Attachment> {
        var request = Mastodon.API.request(
            url: updateMediaEndpointURL(domain: domain, attachmentID: attachmentID),
            method: .PUT,
            query: query,
            authorization: authorization
        )
        request.timeoutInterval = 180    // should > 200 Kb/s for 40 MiB media attachment
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Attachment.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
        
    public struct UpdateMediaQuery: Query {
        
        public let file: Mastodon.API.MediaAttachment?
        public let thumbnail: Mastodon.API.MediaAttachment?
        public let description: String?
        public let focus: String?
        
        public init(
            file: Mastodon.API.MediaAttachment?,
            thumbnail: Mastodon.API.MediaAttachment?,
            description: String?,
            focus: String?
        ) {
            self.file = file
            self.thumbnail = thumbnail
            self.description = description
            self.focus = focus
        }
        
        var contentType: String? {
            return Self.multipartContentType()
        }
        
        var queryItems: [URLQueryItem]? {
            return nil
        }
        
        var body: Data? {
            var data = Data()
            
            // not modify uploaded binary data
            description.flatMap { data.append(Data.multipart(key: "description", value: $0)) }
            focus.flatMap { data.append(Data.multipart(key: "focus", value: $0)) }
            
            data.append(Data.multipartEnd())
            return data
        }
    }
    
}

