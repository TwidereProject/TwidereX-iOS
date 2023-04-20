//
//  Twitter+API+Media.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-26.
//

import Foundation
import Combine

extension Twitter.API.Media {
    static let uploadEndpointURL = Twitter.API.uploadEndpointURL.appendingPathComponent("media/upload.json")
}

extension Twitter.API.Media {
    
    public static func `init`(
        session: URLSession,
        query: InitQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<InitResponse> {
        let request = Twitter.API.request(
            url: uploadEndpointURL,
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: InitResponse.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct InitQuery: Query {
        public let command = "INIT"
        public let totalBytes: Int
        public let mediaType: String
        public let mediaCategory: String
        
        public init(
            totalBytes: Int,
            mediaType: String,
            mediaCategory: String
        ) {
            self.totalBytes = totalBytes
            self.mediaType = mediaType.urlEncoded
            self.mediaCategory = mediaCategory
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "command", value: command))
            items.append(URLQueryItem(name: "total_bytes", value: "\(totalBytes)"))
            items.append(URLQueryItem(name: "media_type", value: mediaType))
            items.append(URLQueryItem(name: "media_category", value: mediaCategory))
            guard !items.isEmpty else { return nil }
            return items
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { "application/x-www-form-urlencoded" }
        var body: Data? { nil }
    }
    
    public struct InitResponse: Codable {
        public let mediaIDString: String
        public let expiresAfterSecs: Int
        
        public enum CodingKeys: String, CodingKey {
            case mediaIDString = "media_id_string"
            case expiresAfterSecs = "expires_after_secs"
        }
    }
    
}

extension Twitter.API.Media {
    
    public static func append(
        session: URLSession,
        query: AppendQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<AppendResponse> {
        var request = Twitter.API.request(
            url: uploadEndpointURL,
            method: .POST,
            query: query,
            authorization: authorization
        )
        request.timeoutInterval = 60    // should > 17 Kb/s for 1 MiB chunk
        
        let (data, response) = try await session.data(for: request, delegate: nil)
        guard data.isEmpty else {
            // try parse and throw error
            do {
                _ = try Twitter.API.decode(type: AppendResponse.self, from: data, response: response)
            } catch {
                throw error
            }
            // error should parsed. return empty response here for edge case 
            assertionFailure()
            return Twitter.Response.Content(value: AppendResponse(), response: response)
        }
        
        return Twitter.Response.Content(value: AppendResponse(), response: response)
    }
    
    public struct AppendQuery: Query {
        public let command = "APPEND"
        public let mediaID: String
        public let mediaData: String
        public let segmentIndex: Int
        
        public init(
            mediaID: String,
            mediaData: String,
            segmentIndex: Int
        ) {
            self.mediaID = mediaID
            self.mediaData = mediaData
            self.segmentIndex = segmentIndex
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "command", value: command))
            items.append(URLQueryItem(name: "media_id", value: mediaID))
            items.append(URLQueryItem(name: "segment_index", value: "\(segmentIndex)"))
            guard !items.isEmpty else { return nil }
            return items
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? {
            [URLQueryItem(name: "media_data", value: mediaData)]
        }
        var contentType: String? { "application/x-www-form-urlencoded" }
        var body: Data? {
            let content = "media_data=" + mediaData.urlEncoded
            return content.data(using: .utf8)
        }
    }
    
    public struct AppendResponse: Codable {
        // Void
    }
    
}

extension Twitter.API.Media {

    public static func finalize(
        session: URLSession,
        query: FinalizeQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<FinalizeResponse> {
        let request = Twitter.API.request(
            url: uploadEndpointURL,
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: FinalizeResponse.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct FinalizeQuery: Query {
        public let command = "FINALIZE"
        public let mediaID: String
        
        public init(mediaID: String) {
            self.mediaID = mediaID
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "command", value: command))
            items.append(URLQueryItem(name: "media_id", value: mediaID))
            guard !items.isEmpty else { return nil }
            return items
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { "application/x-www-form-urlencoded" }
        var body: Data? { nil }
    }
    
    public struct FinalizeResponse: Codable {
        public let mediaIDString: String
        public let size: Int?
        public let expiresAfterSecs: Int
        public let processingInfo: ProcessingInfo?  // server return it when media needs processing
        
        public enum CodingKeys: String, CodingKey {
            case mediaIDString = "media_id_string"
            case size
            case expiresAfterSecs = "expires_after_secs"
            case processingInfo = "processing_info"
        }
        
        public struct ProcessingInfo: Codable {
            public let state: String
            public let checkAfterSecs: Int?
            
            public enum CodingKeys: String, CodingKey {
                case state
                case checkAfterSecs = "check_after_secs"
            }
        }
    }
    
}

extension Twitter.API.Media {

    public static func status(
        session: URLSession,
        query: StatusQuery,
        authorization: Twitter.API.OAuth.Authorization
    ) async throws -> Twitter.Response.Content<FinalizeResponse> {
        let request = Twitter.API.request(
            url: uploadEndpointURL,
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: FinalizeResponse.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }
    
    public struct StatusQuery: Query {
        public let command = "STATUS"
        public let mediaID: String
        
        public init(mediaID: String) {
            self.mediaID = mediaID
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "command", value: command))
            items.append(URLQueryItem(name: "media_id", value: mediaID))
            guard !items.isEmpty else { return nil }
            return items
        }
        var encodedQueryItems: [URLQueryItem]? { nil }
        var formQueryItems: [URLQueryItem]? { nil }
        var contentType: String? { nil }
        var body: Data? { nil }
    }
    
}
