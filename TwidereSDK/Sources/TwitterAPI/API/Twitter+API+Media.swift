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
    
    public static func `init`(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: InitQuery) -> AnyPublisher<Twitter.Response.Content<InitResponse>, Error> {
        var request = Twitter.API.request(url: uploadEndpointURL, httpMethod: "POST", authorization: authorization, queryItems: query.queryItems)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: InitResponse.self, from: data, response: response)
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func append(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: AppendQuery, mediaData: String) -> AnyPublisher<Twitter.Response.Content<AppendResponse>, Error> {
        var request = Twitter.API.request(url: uploadEndpointURL, httpMethod: "POST", authorization: authorization, queryItems: query.queryItems, formQueryItems: [URLQueryItem(name: "media_data", value: mediaData)])
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = ("media_data=" + mediaData.urlEncoded).data(using: .utf8)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard data.isEmpty else {
                    do {
                        _ = try Twitter.API.decode(type: AppendResponse.self, from: data, response: response)
                    } catch {
                        throw error
                    }
                    assertionFailure()
                    return Twitter.Response.Content(value: AppendResponse(), response: response)
                }
                
                return Twitter.Response.Content(value: AppendResponse(), response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func finalize(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: FinalizeQuery) -> AnyPublisher<Twitter.Response.Content<FinalizeResponse>, Error> {
        var request = Twitter.API.request(url: uploadEndpointURL, httpMethod: "POST", authorization: authorization, queryItems: query.queryItems)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Twitter.API.decode(type: FinalizeResponse.self, from: data, response: response)
                return Twitter.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Twitter.API.Media {
    
    public struct InitQuery {
        public let command = "INIT"
        public let totalBytes: Int
        public let mediaType: String
        
        public init(totalBytes: Int, mediaType: String) {
            self.totalBytes = totalBytes
            self.mediaType = mediaType.urlEncoded
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "command", value: command))
            items.append(URLQueryItem(name: "total_bytes", value: "\(totalBytes)"))
            items.append(URLQueryItem(name: "media_type", value: mediaType))
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
    public struct InitResponse: Codable {
        public let mediaIDString: String
        public let expiresAfterSecs: Int
        
        public enum CodingKeys: String, CodingKey {
            case mediaIDString = "media_id_string"
            case expiresAfterSecs = "expires_after_secs"
        }
    }
    
    public struct AppendQuery {
        public let command = "APPEND"
        public let mediaID: String
        public let segmentIndex: Int
        
        public init(mediaID: String, segmentIndex: Int) {
            self.mediaID = mediaID
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
    }
    
    public struct AppendResponse: Codable {
        // Void
    }

    public struct FinalizeQuery {
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
    }
    
    public struct FinalizeResponse: Codable {
        public let mediaIDString: String
        public let size: Int
        public let expiresAfterSecs: Int
        public let processingInfo: ProcessingInfo?
        
        public enum CodingKeys: String, CodingKey {
            case mediaIDString = "media_id_string"
            case size
            case expiresAfterSecs = "expires_after_secs"
            case processingInfo = "processing_info"
        }
        
        public struct ProcessingInfo: Codable {
            public let state: String
            public let checkAfterSecs: Int
            
            public enum CodingKeys: String, CodingKey {
                case state
                case checkAfterSecs = "check_after_secs"
                
            }
        }
    }
    
}
