//
//  Twitter+Entity+Relationship.swift
//  
//
//  Created by Cirno MainasuK on 2020-12-23.
//

import Foundation

extension Twitter.Entity {
    
    public struct Relationship: Codable {
        public let source: RelationshipSource
        public let target: RelationshipTarget
        
        enum CodingKeys: String, CodingKey {
            case relationship
        }
        
        enum RelationshipKeys: String, CodingKey {
            case source
            case target
        }
        
        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let relationshipValues = try values.nestedContainer(keyedBy: RelationshipKeys.self, forKey: .relationship)
            source = try relationshipValues.decode(RelationshipSource.self, forKey: .source)
            target = try relationshipValues.decode(RelationshipTarget.self, forKey: .target)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            var relationshipContainer = container.nestedContainer(keyedBy: RelationshipKeys.self, forKey: .relationship)
            try relationshipContainer.encode(source, forKey: .source)
            try relationshipContainer.encode(target, forKey: .target)
        }
    }
    
    public struct RelationshipSource: Codable {
        public typealias ID = String

        public let idStr: ID
        public let screenName: String
        public let following: Bool
        public let followedBy: Bool
        public let liveFollowing: Bool
        public let followingReceived: Bool
        public let followingRequested: Bool
        public let notificationsEnabled: Bool
        public let canDM: Bool
        public let blocking: Bool
        public let blockedBy: Bool
        public let muting: Bool
        public let wantRetweets: Bool
        public let allReplies: Bool
        public let markedSpam: Bool
        
        enum CodingKeys: String, CodingKey {
            case idStr = "id_str"
            case screenName = "screen_name"
            case following = "following"
            case followedBy = "followed_by"
            case liveFollowing = "live_following"
            case followingReceived = "following_received"
            case followingRequested = "following_requested"
            case notificationsEnabled = "notifications_enabled"
            case canDM = "can_dm"
            case blocking = "blocking"
            case blockedBy = "blocked_by"
            case muting = "muting"
            case wantRetweets = "want_retweets"
            case allReplies = "all_replies"
            case markedSpam = "marked_spam"
        }
    }
    
    public struct RelationshipTarget: Codable {
        public typealias ID = String

        public let idStr: ID
        public let screenName: String
        public let following: Bool
        public let followedBy: Bool
        public let followingReceived: Bool
        public let followingRequested: Bool
        
        enum CodingKeys: String, CodingKey {
            case idStr = "id_str"
            case screenName = "screen_name"
            case following = "following"
            case followedBy = "followed_by"
            case followingReceived = "following_received"
            case followingRequested = "following_requested"
        }
    }
    
}
