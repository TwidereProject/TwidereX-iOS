//
//  Twitter+Entity+V2+Tweet+Entities.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-19.
//

import Foundation

extension Twitter.Entity.V2 {
    public struct Entities: Codable {
        public let urls: [URL]?
        public let hashtags: [Hashtag]?
        public let mentions: [Mention]?
    }
}

extension Twitter.Entity.V2.Entities {
    
    public struct URL: Codable {
        public let start: Int
        public let end: Int
        public let url: String
        public let expandedURL: String
        public let displayURL: String
        
        // optional
        public let status: Int?
        public let title: String?
        public let description: String?
        public let unwoundURL: String?
        
        
        public enum CodingKeys: String, CodingKey {
            case start = "start"
            case end = "end"
            case url = "url"
            case expandedURL = "expanded_url"
            case displayURL = "display_url"
            case status
            case title
            case description
            case unwoundURL = "unwound_url"
        }
    }
    
    public struct Hashtag: Codable {
        public let start: Int
        public let end: Int
        public let tag: String
        
        public enum CodingKeys: String, CodingKey {
            case start = "start"
            case end = "end"
            case tag = "tag"
        }
    }
    
    public struct Mention: Codable {
        public let start: Int
        public let end: Int
        public let username: String
    }

}
