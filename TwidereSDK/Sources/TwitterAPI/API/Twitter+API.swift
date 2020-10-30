//
//  Twitter+API.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation

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
    
    public enum Account { }
    public enum Favorites { }
    public enum Geo { }
    public enum Media { }
    public enum OAuth { }
    public enum Statuses { }
    public enum Timeline { }
    public enum Users { }
    
    // V2
    public enum V2 {
        public enum Lookup { }
        public enum RecentSearch { }        
    }
}

extension Twitter.API {
    enum APIError: Error, LocalizedError {
        case `internal`(message: String)
        case response(code: Int, reason: String)
        case responseV2(title: String?, detail: String?)        // v2
        
        var errorDescription: String? {
            switch self {
            case .internal(let message):
                return "Internal error: \(message)"
            case .response(let code, let reason):
                return "\(code) - \(reason)"
            case .responseV2(let title, let detail):
                return [title, detail].compactMap { $0 }.joined(separator: " - ")
            }
        }
    }
    
    public struct ErrorResponse: Codable {
        public let errors: [ErrorDescription]
        
        public struct ErrorDescription: Codable {
            public let code: Int
            public let message: String
        }
    }
    
    public struct ErrorResponseV2: Codable {
        public let errors: [ErrorDescription]
        public let title: String?
        public let detail: String?
        public let type: String?
        
        public struct ErrorDescription: Codable {
            public let parameters: ErrorDescriptionParameters
            public let message: String
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
            if let errorResponse = try? Twitter.API.decoder.decode(ErrorResponse.self, from: data),
               let error = errorResponse.errors.first {
                throw APIError.response(code: error.code, reason: error.message)
            }
            
            if let errorResponse = try? Twitter.API.decoder.decode(ErrorResponseV2.self, from: data) {
                throw APIError.responseV2(title: errorResponse.title, detail: errorResponse.detail)
            }
            
            throw decodeError
        }
    }
    
    static func request(url: URL, httpMethod: String, authorization: Twitter.API.OAuth.Authorization, queryItems: [URLQueryItem]?, formQueryItems: [URLQueryItem]? = nil) -> URLRequest {
        var components = URLComponents(string: url.absoluteString)!
        components.queryItems = queryItems
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
        return request
    }
}

extension JSONDecoder.DateDecodingStrategy {
    fileprivate static let twitterStrategy = custom { decoder throws -> Date in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        
        let formatterV1 = DateFormatter()
        formatterV1.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
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
