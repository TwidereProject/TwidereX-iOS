//
//  Twitter+API.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation

extension Twitter.API {
    
    public static let endpointURL = URL(string: "https://api.twitter.com/1.1/")!
    public static let timeoutInterval: TimeInterval = 10
    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .twitterStrategy
        return decoder
    }()
    
    public enum OAuth { }
    public enum Timeline { }
}

extension Twitter.API {
    enum APIError: Error, LocalizedError {
        case `internal`
        case response(code: Int, reason: String)
        
        var errorDescription: String? {
            switch self {
            case .internal:
                return "Internal error."
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
        if let errorResponse = try? Twitter.API.decoder.decode(ErrorResponse.self, from: data),
           let error = errorResponse.errors.first {
            throw APIError.response(code: error.code, reason: error.message)
        }
        
        do {
            return try Twitter.API.decoder.decode(type, from: data)
        } catch {
            assertionFailure(error.localizedDescription)
            throw error
        }
    }
}

extension JSONDecoder.DateDecodingStrategy {
    fileprivate static let twitterStrategy = custom { decoder throws -> Date in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        if let date = formatter.date(from: string) {
            return date
        }
        
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
    }
}
