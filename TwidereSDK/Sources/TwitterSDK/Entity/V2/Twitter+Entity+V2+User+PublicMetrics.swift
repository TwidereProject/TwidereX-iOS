//
//  Twitter+Entity+V2+User+PublicMetrics.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-20.
//

import Foundation

extension Twitter.Entity.V2.User {
    public struct PublicMetrics: Codable {
        public let followersCount: Int
        public let followingCount: Int
        public let tweetCount: Int
        public let listedCount: Int
        
        public enum CodingKeys: String, CodingKey {
            case followersCount = "followers_count"
            case followingCount = "following_count"
            case tweetCount = "tweet_count"
            case listedCount = "listed_count"
        }
    }
}
