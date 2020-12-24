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
