//
//  Twitter+Entity+V2+Tweet+PublicMetrics.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-19.
//

import Foundation

extension Twitter.Entity.V2.Tweet {
    public struct PublicMetrics: Codable {
        public let retweetCount: Int
        public let replyCount: Int
        public let likeCount: Int
        public let quoteCount: Int
        
        public enum CodingKeys: String, CodingKey {
            case retweetCount = "retweet_count"
            case replyCount = "reply_count"
            case likeCount = "like_count"
            case quoteCount = "quote_count"
        }
    }
}
