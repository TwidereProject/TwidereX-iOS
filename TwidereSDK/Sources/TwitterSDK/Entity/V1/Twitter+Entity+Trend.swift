//
//  Twitter+Entity+Trend.swift
//  
//
//  Created by MainasuK on 2021-12-27.
//

import Foundation

extension Twitter.Entity {
    public struct Trend: Codable, Hashable {
        public let name: String
        public let url: String
        public let query: String
        public let tweetVolume: Int?

        enum CodingKeys: String, CodingKey {
            case name = "name"
            case url = "url"
            case query = "query"
            case tweetVolume = "tweet_volume"
        }

        public init(
            name: String,
            url: String,
            query: String,
            tweetVolume: Int?
        ) {
            self.name = name
            self.url = url
            self.query = query
            self.tweetVolume = tweetVolume
        }
    }
}
