//
//  Twitter+Entity+Tweet+Entities.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation

extension Twitter.Entity.Tweet {
    public struct Entities: Codable {
        public let symbols: [Symbol]?
        public let userMentions: [UserMention]?
        public let urls: [URL]?
        public let hashtags: [Hashtag]?
        public let polls: [Poll]?
        
        public enum CodingKeys: String, CodingKey {
            case symbols = "symbols"
            case userMentions = "user_mentions"
            case urls = "urls"
            case hashtags = "hashtags"
            case polls = "polls"
        }
    }
}

extension Twitter.Entity.Tweet.Entities: Equatable { }

extension Twitter.Entity.Tweet.Entities {
    
    public struct Symbol: Codable {
        public let text: String?
        public let indices: [Int]?
        
        enum CodingKeys: String, CodingKey {
            case text = "text"
            case indices = "indices"
        }
    }
    
    public struct UserMention: Codable {
        public let screenName: String?      /// username
        public let name: String?            /// nickname
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

extension Twitter.Entity.Tweet.Entities.Symbol: Equatable { }
extension Twitter.Entity.Tweet.Entities.UserMention: Equatable { }
extension Twitter.Entity.Tweet.Entities.URL: Equatable { }
extension Twitter.Entity.Tweet.Entities.Hashtag: Equatable { }
extension Twitter.Entity.Tweet.Entities.Poll: Equatable { }
extension Twitter.Entity.Tweet.Entities.Poll.Option: Equatable { }
