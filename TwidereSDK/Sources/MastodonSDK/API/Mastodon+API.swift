//
//  Mastodon+API.swift
//  Mastodon+API
//
//  Created by Cirno MainasuK on 2021-8-17.
//

import os.log
import Foundation
import enum NIOHTTP1.HTTPResponseStatus

extension Mastodon.API {
    
    static func oauthEndpointURL(domain: String) -> URL {
        return URL(string: "https://" + domain + "/oauth/")!
    }
    static func endpointURL(domain: String) -> URL {
        return URL(string: "https://" + domain + "/api/v1/")!
    }
    static func endpointV2URL(domain: String) -> URL {
        return URL(string: "https://" + domain + "/api/v2/")!
    }
    
    static let timeoutInterval: TimeInterval = 10
    
    static let httpHeaderDateFormatter: ISO8601DateFormatter = {
        var formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        return formatter
    }()
    static let fractionalSecondsPreciseISO8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        return formatter
    }()
    static let fullDatePreciseISO8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter
    }()
    
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.custom { decoder throws -> Date in
            let container = try decoder.singleValueContainer()
            
            var logInfo = ""
            do {
                let string = try container.decode(String.self)
                logInfo += string
                
                if let date = fractionalSecondsPreciseISO8601Formatter.date(from: string) {
                    return date
                }
                if let date = fullDatePreciseISO8601Formatter.date(from: string) {
                    return date
                }
                if let timestamp = TimeInterval(string) {
                    return Date(timeIntervalSince1970: timestamp)
                }
            } catch {
                // do nothing
            }
            
            var numberValue = ""
            do {
                let number = try container.decode(Double.self)
                logInfo += "\(number)"
                
                return Date(timeIntervalSince1970: number)
            } catch {
                // do nothing
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "[Decoder] Invalid date: \(logInfo)")
        }
        
        return decoder
    }()
    
}

extension Mastodon.API {

    public enum Account { }
    public enum App { }
    public enum CustomEmoji { }
    public enum Favorite { }
    public enum Instance { }
    public enum Media { }
    public enum OAuth { }
    public enum Onboarding { }
    public enum Poll { }
    public enum Reblog { }
    public enum Status { }
    public enum Timeline { }
    public enum Trends { }
    public enum Suggestion { }
    public enum Notification { }
    public enum Subscription { }
    public enum Report { }
    public enum DomainBlock { }
    
    public enum V2 {
        public enum Search { }
    }
}

extension Mastodon.API {

    enum Method: String {
        case GET, POST, PATCH, PUT, DELETE
    }
    
    static func request(
        url: URL,
        method: Method,
        query: Query?,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> URLRequest {
        var components = URLComponents(string: url.absoluteString)!
        components.queryItems = query?.queryItems
        
        let requestURL = components.url!
        var request = URLRequest(
            url: requestURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: Mastodon.API.timeoutInterval
        )
        request.httpMethod = method.rawValue
        
        if let contentType = query?.contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        
        if let body = query?.body {
            request.httpBody = body
            request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        }
        
        if let authorization = authorization {
            request.setValue(
                "Bearer \(authorization.accessToken)",
                forHTTPHeaderField: Mastodon.API.OAuth.authorizationField
            )
        }
        
        return request
    }

}

extension Mastodon.API {

    static func decode<T>(type: T.Type, from data: Data, response: URLResponse) throws -> T where T : Decodable {
        // decode data then decode error if could
        do {
            return try Mastodon.API.decoder.decode(type, from: data)
        } catch let decodeError {
            #if DEBUG
            os_log(.info, "%{public}s[%{public}ld], %{public}s: decode fail. content %s", ((#file as NSString).lastPathComponent), #line, #function, String(data: data, encoding: .utf8) ?? "<nil>")
            debugPrint(decodeError)
            #endif
            
            guard let httpURLResponse = response as? HTTPURLResponse else {
                assertionFailure()
                throw decodeError
            }
            
            let httpResponseStatus = HTTPResponseStatus(statusCode: httpURLResponse.statusCode)
            if let error = try? Mastodon.API.decoder.decode(Mastodon.Entity.Error.self, from: data) {
                throw Mastodon.API.Error(httpResponseStatus: httpResponseStatus, error: error)
            }
            
            throw Mastodon.API.Error(httpResponseStatus: httpResponseStatus, mastodonError: nil)
        }
    }

}
