//
//  TwitterEntity.swift
//  TwitterEntity
//
//  Created by Cirno MainasuK on 2021-9-9.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

final public class TwitterEntity: NSObject, Codable {
    public let urls: [URLEntity]?
    public let hashtags: [Hashtag]?
    public let mentions: [Mention]?
    
    public init(
        urls: [TwitterEntity.URLEntity]?,
        hashtags: [TwitterEntity.Hashtag]?,
        mentions: [TwitterEntity.Mention]?
    ) {
        self.urls = urls
        self.hashtags = hashtags
        self.mentions = mentions
    }
}

extension TwitterEntity {
    public struct URLEntity: Codable {
        public let start: Int
        public let end: Int
        public let url: String
        
        public let expandedURL: String?
        public let displayURL: String?
        public let status: Int?
        public let title: String?
        public let description: String?
        public let unwoundURL: String?
        
        public init(start: Int, end: Int, url: String, expandedURL: String?, displayURL: String?, status: Int?, title: String?, description: String?, unwoundURL: String?) {
            self.start = start
            self.end = end
            self.url = url
            self.expandedURL = expandedURL
            self.displayURL = displayURL
            self.status = status
            self.title = title
            self.description = description
            self.unwoundURL = unwoundURL
        }
    }
    
    public struct Hashtag: Codable {
        public let start: Int
        public let end: Int
        public let tag: String
        
        public init(start: Int, end: Int, tag: String) {
            self.start = start
            self.end = end
            self.tag = tag
        }
    }
    
    public struct Mention: Codable {
        public let start: Int
        public let end: Int
        public let username: String
        public let id: String?
        
        public init(start: Int, end: Int, username: String, id: String?) {
            self.start = start
            self.end = end
            self.username = username
            self.id = id
        }
    }
}
