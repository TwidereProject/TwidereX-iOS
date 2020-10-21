//
//  Twitter+Entity+V2+User.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-16.
//

import Foundation

extension Twitter.Entity.V2 {
    public struct User: Codable {
        public typealias ID = String
        
        // Fundamental
        public let id: ID
        public let name: String
        public let username: String
        
        // Extra
        public let createdAt: Date?
        public let description: String?
        public let entities: Entities?
        public let location: String?
        public let pinnedTweetID: Tweet.ID?
        public let profileImageURL: String?
        public let protected: Bool?
        public let publicMetrics: PublicMetrics?
        public let url: String?
        public let verified: Bool?
        public let withheld: Withheld?
        
        public enum CodingKeys: String, CodingKey {
            case id
            case name
            case username
            
            case createdAt = "created_at"
            case description = "description"
            case entities = "entities"
            case location = "location"
            case pinnedTweetID = "pinned_tweet_id"
            case profileImageURL = "profile_image_url"
            case protected = "protected"
            case publicMetrics = "public_metrics"
            case url = "url"
            case verified = "verified"
            case withheld = "withheld"
        }
    }
}
