//
//  Twitter.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-1.
//

import Foundation

public enum Twitter {
    public enum Request { }
    public enum API { }
    public enum Entity { }
}

extension Twitter {
    public struct Response<T> {
        // entity
        public let value: T
        
        // standard fields
        public let date: Date?
        
        // application fields
        public let rateLimit: RateLimit?
        public let responseTime: Int?
        
        public var networkDate: Date {
            return date ?? Date()
        }
        
        public init(value: T, response: URLResponse) {
            self.value = value
            
            self.date = {
                guard let string = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "date") else { return nil }
                return Twitter.API.httpHeaderDateFormatter.date(from: string)
            }()
            
            self.rateLimit = RateLimit(response: response)
            self.responseTime = {
                guard let string = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "x-response-time") else { return nil }
                return Int(string)
            }()
        
        }
    }
}

extension Twitter.Response {
    public struct RateLimit {
        public let limit: Int
        public let remaining: Int
        public let reset: Date
        
        public init(limit: Int, remaining: Int, reset: Date) {
            self.limit = limit
            self.remaining = remaining
            self.reset = reset
        }
        
        public init?(response: URLResponse) {
            guard let response = response as? HTTPURLResponse else {
                return nil
            }
            
            guard let limitString = response.value(forHTTPHeaderField: "x-rate-limit-limit"),
                  let limit = Int(limitString),
                  let remainingString = response.value(forHTTPHeaderField: "x-rate-limit-remaining"),
                  let remaining = Int(remainingString) else {
                return nil
            }
            
            guard let resetTimestampString = response.value(forHTTPHeaderField: "x-rate-limit-reset"),
                  let resetTimestamp = Int(resetTimestampString) else {
                return nil
            }
            let reset = Date(timeIntervalSince1970: Double(resetTimestamp))
                  
            self.init(limit: limit, remaining: remaining, reset: reset)
        }
    }
}





