//
//  Twitter+Entity+RateLimitStatus.swift
//  
//
//  Created by Cirno MainasuK on 2020-12-7.
//

import Foundation
import SwiftyJSON

extension Twitter.Entity {
    /// https://developer.twitter.com/en/docs/twitter-api/v1/developer-utilities/rate-limit-status/overview
    public struct RateLimitStatus: Codable {
        
        public let rateLimitContext: RateLimitContext
        public let resources: JSON
        
        enum CodingKeys: String, CodingKey {
            case rateLimitContext = "rate_limit_context"
            case resources
        }
        
        public struct RateLimitContext: Codable {
            public let accessToken: String
            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
            }
        }
    }
}

extension Twitter.Entity.RateLimitStatus {
    public struct Status: Codable {
        public let limit: Int
        public let remaining: Int
        public let reset: Int
    }
}
