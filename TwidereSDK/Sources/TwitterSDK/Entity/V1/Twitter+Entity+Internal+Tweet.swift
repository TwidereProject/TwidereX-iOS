//
//  Twitter+Tweet.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation

extension Twitter.Entity.Internal {
    public class Tweet: Codable {
        
        public typealias ID = String

        // Fundamental
        public let createdAt: Date
        public let idStr: ID
        
        public let text: String?
        
        public let userIDStr: Twitter.Entity.User.ID
        
        public let entities: Twitter.Entity.Tweet.Entities?
        
        // public let coordinates: Coordinates?
        // public let place: Place?

        //let contributors: JSONNull?
        public let favoriteCount: Int?

        public let retweeted: Bool
        public let retweetCount: Int?
        public let retweetedStatusIDStr: ID?

        public let inReplyToScreenName: String?
        public let inReplyToStatusIDStr: ID?
        public let inReplyToUserIDStr: Twitter.Entity.User.ID?
        
        public let isQuoteStatus: Bool
        public let quotedStatusIDStr: String?

        public let lang: String?
        
        //let possiblySensitive: Bool?
        //let possiblySensitiveAppealable: Bool?

        public let source: String?
        public let truncated: Bool?
        
        public enum CodingKeys: String, CodingKey {
            // Fundamental
            case createdAt = "created_at"
            case idStr = "id_str"
            
            case text
            
            case userIDStr = "user_id_str"
            
            case entities
            
            // case coordinates = "coordinates"
            // case place = "place"

            //case contributors = "contributors"
            case favoriteCount = "favorite_count"
            
            case retweeted = "retweeted"
            case retweetCount = "retweet_count"
            case retweetedStatusIDStr = "retweeted_status_id_str"
            
            case inReplyToScreenName = "in_reply_to_screen_name"
            case inReplyToStatusIDStr = "in_reply_to_status_id_str"
            case inReplyToUserIDStr = "in_reply_to_user_id_str"
            
            case isQuoteStatus = "is_quote_status"
            case quotedStatusIDStr = "quoted_status_id_str"
            
            case lang
            
            //case possiblySensitive = "possibly_sensitive"
            //case possiblySensitiveAppealable = "possibly_sensitive_appealable"
            
            case source
            case truncated
        }
    }
}

extension Twitter.Entity.Internal.Tweet: Hashable {
    
    public static func == (lhs: Twitter.Entity.Internal.Tweet, rhs: Twitter.Entity.Internal.Tweet) -> Bool {
        lhs.idStr == rhs.idStr
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(idStr)
    }
    
}
