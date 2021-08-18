//
//  Twitter+API.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
import NIOHTTP1

extension Twitter.API {
    
    public static let endpointURL = URL(string: "https://api.twitter.com/1.1/")!
    public static let endpointV2URL = URL(string: "https://api.twitter.com/2/")!
    public static let uploadEndpointURL = URL(string: "https://upload.twitter.com/1.1/")!
    
    public static let timeoutInterval: TimeInterval = 10
    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .twitterStrategy
        return decoder
    }()
    public static let httpHeaderDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter
    }()
    
}

extension Twitter.API {
    
    public enum Error { }
    
    public enum Account { }
    public enum Application { }
    public enum Block { }
    public enum Favorites { }
    public enum Friendships { }
    public enum Geo { }
    public enum Lookup { }
    public enum Media { }
    public enum Mute { }
    public enum OAuth { }
    public enum Search { }
    public enum Statuses { }
    public enum Timeline { }
    public enum Users { }
    
    // V2
    public enum V2 {
        public enum FollowLookup { }
        public enum Lookup { }
        public enum RecentSearch { }
        public enum UserLookup { } 
    }
    
}

extension Twitter.API {
    // Error Response when request V1 endpoint
    struct ErrorResponse: Codable {
        let errors: [ErrorDescription]
        
        struct ErrorDescription: Codable {
            public let code: Int
            public let message: String
        }
    }
    
    // Alternative Error Response when request V1 endpoint
    struct ErrorRequestResponse: Codable {
        let request: String
        let error: String
    }
    
    public struct ErrorResponseV2: Codable {
        public let errors: [ErrorDescription]
        public let title: String?
        public let detail: String?
        public let type: String?

        public struct ErrorDescription: Codable {
            public let parameter: String?
            public let parameters: ErrorDescriptionParameters?
            
            public let value: String?
            public let message: String?
            
            public let title: String?
            public let detail: String?
            public let type: String?
        }

        public struct ErrorDescriptionParameters: Codable {
            public let expansions: [String]?
            public let mediaFields: [String]?
            public let placeFields: [String]?
            public let poolFields: [String]?
            public let userFields: [String]?
            public let tweetFields: [String]?

            public enum CodingKeys: String, CodingKey {
                case expansions
                case mediaFields = "media.fields"
                case placeFields = "place.fields"
                case poolFields = "pool.fields"
                case userFields = "user.fields"
                case tweetFields = "tweet.fields"
            }
        }
    }
}

extension Twitter.API {
    static func decode<T>(type: T.Type, from data: Data, response: URLResponse) throws -> T where T : Decodable {
        // decode data then decode error if could
        do {
            return try Twitter.API.decoder.decode(type, from: data)
        } catch let decodeError {
            guard let httpURLResponse = response as? HTTPURLResponse else {
                assertionFailure()
                throw decodeError
            }
            let httpResponseStatus = HTTPResponseStatus(statusCode: httpURLResponse.statusCode)
            
            if let errorResponse = try? Twitter.API.decoder.decode(ErrorResponse.self, from: data),
               let twitterAPIError = Error.TwitterAPIError(errorResponse: errorResponse) {
                throw Error.ResponseError(httpResponseStatus: httpResponseStatus, twitterAPIError: twitterAPIError)
            }
            
            if let errorRequestResponse = try? Twitter.API.decoder.decode(ErrorRequestResponse.self, from: data),
               let twitterAPIError = Error.TwitterAPIError(errorRequestResponse: errorRequestResponse) {
                throw Error.ResponseError(httpResponseStatus: httpResponseStatus, twitterAPIError: twitterAPIError)
            }
            
            if let errorResponseV2 = try? Twitter.API.decoder.decode(ErrorResponseV2.self, from: data),
               let twitterAPIError = Error.TwitterAPIError(errorResponseV2: errorResponseV2) {
                throw Error.ResponseError(httpResponseStatus: httpResponseStatus, twitterAPIError: twitterAPIError)
            }
            
            // Twitter not return error code described in the document. Convert manually
            if httpURLResponse.statusCode == 429 {
                throw Error.ResponseError(httpResponseStatus: httpResponseStatus, twitterAPIError: .rateLimitExceeded)
            }
            
            debugPrint(decodeError)
            throw Error.ResponseError(httpResponseStatus: httpResponseStatus, twitterAPIError: nil)
        }
    }
    
    static func request(url: URL, httpMethod: String, authorization: Twitter.API.OAuth.Authorization, queryItems: [URLQueryItem]? = nil, encodedQueryItems: [URLQueryItem]? = nil, formQueryItems: [URLQueryItem]? = nil) -> URLRequest {
        var components = URLComponents(string: url.absoluteString)!
        components.queryItems = queryItems
        if let encodedQueryItems = encodedQueryItems {
            components.percentEncodedQueryItems = (components.percentEncodedQueryItems ?? []) + encodedQueryItems
        }
        let requestURL = components.url!
        var request = URLRequest(
            url: requestURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: Twitter.API.timeoutInterval
        )
        request.setValue(
            authorization.authorizationHeader(requestURL: requestURL, requestFormQueryItems: formQueryItems, httpMethod: httpMethod),
            forHTTPHeaderField: Twitter.API.OAuth.authorizationField
        )
        request.httpMethod = httpMethod
        return request
    }
}

extension JSONDecoder.DateDecodingStrategy {
    fileprivate static let twitterStrategy = custom { decoder throws -> Date in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        
        let formatterV1 = DateFormatter()
        formatterV1.locale = Locale(identifier: "en")
        formatterV1.dateFormat = "EEE MMM dd HH:mm:ss ZZZZZ yyyy"
        if let date = formatterV1.date(from: string) {
            return date
        }
        
        let formatterV2 = ISO8601DateFormatter()
        formatterV2.formatOptions.insert(.withFractionalSeconds)
        if let date = formatterV2.date(from: string) {
            return date
        }        
        
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
    }
}
