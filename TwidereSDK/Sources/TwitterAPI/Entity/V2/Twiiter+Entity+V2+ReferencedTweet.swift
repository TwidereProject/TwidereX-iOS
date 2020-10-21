//
//  Twiiter+Entity+V2+ReferencedTweet.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-19.
//

import Foundation

extension Twitter.Entity.V2.Tweet {
    public struct ReferencedTweet: Codable {
        public let `type`: ReferencedType?
        public let id: Twitter.Entity.V2.Tweet.ID?
        
        public enum CodingKeys: String, CodingKey {
            case `type` = "type"
            case id
        }
    }
    
}

extension Twitter.Entity.V2.Tweet.ReferencedTweet {
    public enum ReferencedType: String, Codable {
        case repliedTo = "replied_to"
        case quoted
        case retweeted
        
        public enum CodingKeys: String, CodingKey {
            case repliedTo = "replied_to"
            case quoted
            case retweeted
        }
    }
}
