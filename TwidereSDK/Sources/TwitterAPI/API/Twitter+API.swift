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
    
    public enum OAuth { }
    public enum Timeline { }
    public enum Lookup { }
}

extension Twitter.API {
    enum APIError: Error, LocalizedError {
        case `internal`(message: String)
        case response(code: Int, reason: String)
        
        var errorDescription: String? {
            switch self {
            case .internal(let message):
                return "Internal error: \(message)"
            case .response(let code, let reason):
                return "\(code) - \(reason)"
            }
        }
    }
    
    struct ErrorResponse: Codable {
        let errors: [ErrorDescription]
        
        struct ErrorDescription: Codable {
            let code: Int
            let message: String
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
            
            throw decodeError
        }
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
        if let date = formatterV2.date(from: string) {
            return date
        }        
        
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
    }
}
