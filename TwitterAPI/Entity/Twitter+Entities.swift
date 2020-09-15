//
//  Twitter+Entities.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
extension Twitter.Entity {
    public struct Entities: Codable {
        
        public let symbols: [Symbol]
        public let userMentions: [UserMention]
        public let urls: [URL]
        public let hashtags: [Hashtag]
        public let polls: [Poll]?
        
        public init() {
            self.symbols = []
            self.userMentions = []
            self.urls = []
            self.hashtags = []
            self.polls = nil
        }
        
        public init(symbols: [Twitter.Entity.Entities.Symbol], userMentions: [Twitter.Entity.Entities.UserMention], urls: [Twitter.Entity.Entities.URL], hashtags: [Twitter.Entity.Entities.Hashtag], polls: [Twitter.Entity.Entities.Poll]?) {
            self.symbols = symbols
            self.userMentions = userMentions
            self.urls = urls
            self.hashtags = hashtags
            self.polls = polls
        }
        
        public enum CodingKeys: String, CodingKey {
            case symbols = "symbols"
            case userMentions = "user_mentions"
            case urls = "urls"
            case hashtags = "hashtags"
            case polls = "polls"
        }
    }
}

extension Twitter.Entity.Entities {
    
    public struct Symbol: Codable {
        public let text: String?
        public let indices: [Int]?
        
        enum CodingKeys: String, CodingKey {
            case text = "text"
            case indices = "indices"
        }
    }
    
    public struct UserMention: Codable {
        public let screenName: String?
        public let name: String?
        public let id: Int?
        public let idStr: String?
        public let indices: [Int]?
        
        enum CodingKeys: String, CodingKey {
            case screenName = "screen_name"
            case name = "name"
            case id = "id"
            case idStr = "id_str"
            case indices = "indices"
        }
    }
    
    public struct URL: Codable {
        public let url: String?
        public let expandedURL: String?
        public let displayURL: String?
        public let indices: [Int]?
        
        enum CodingKeys: String, CodingKey {
            case url = "url"
            case expandedURL = "expanded_url"
            case displayURL = "display_url"
            case indices = "indices"
        }
    }
    
    public struct Hashtag: Codable {
        public let text: String?
        public let indices: [Int]?
        
        enum CodingKeys: String, CodingKey {
            case text = "text"
            case indices = "indices"
        }
    }
    
    public struct Poll: Codable {
        public let options: [Option]?
        public let endDatetime: String?
        public let durationMinutes: Int?
        
        enum CodingKeys: String, CodingKey {
            case options = "options"
            case endDatetime = "end_datetime"
            case durationMinutes = "duration_minutes"
        }
        
        public init(options: [Option]?, endDatetime: String?, durationMinutes: Int?) {
            self.options = options
            self.endDatetime = endDatetime
            self.durationMinutes = durationMinutes
        }
    
        // MARK: - Option
        public struct Option: Codable {
            public let position: Int?
            public let text: String?
            
            enum CodingKeys: String, CodingKey {
                case position = "position"
                case text = "text"
            }
            
            public init(position: Int?, text: String?) {
                self.position = position
                self.text = text
            }
        }
    }
    
}
