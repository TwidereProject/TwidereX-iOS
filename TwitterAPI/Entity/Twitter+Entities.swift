//
//  Twitter+Entities.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
extension Twitter.Entity {
    public struct Entities: Codable {
        public let symbols: [Symbol]?
        public let userMentions: [UserMention]?
        public let urls: [URL]?
        public let hashtags: [Hashtag]?
        
        public enum CodingKeys: String, CodingKey {
            case symbols = "symbols"
            case userMentions = "user_mentions"
            case urls = "urls"
            case hashtags = "hashtags"
        }
    }
}

extension Twitter.Entity.Entities {
    public struct Symbol: Codable {
        
    }
    public struct UserMention: Codable {
        
    }
    public struct URL: Codable {
        
    }
    public struct Hashtag: Codable {
        
    }
}
