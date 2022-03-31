//
//  Twitter+Entity+V2+List.swift
//  
//
//  Created by MainasuK on 2022-2-28.
//

import Foundation

extension Twitter.Entity.V2 {
    public struct List: Codable {
        public typealias ID = String
        
        public let id: ID
        public let name: String
        
        public let `private`: Bool?
        public let memberCount: Int?
        public let followerCount: Int?
        public let description: String?
        public let ownerID: Twitter.Entity.V2.User.ID?
        public let createdAt: Date?
        
        public enum CodingKeys: String, CodingKey {
            case id
            case name
            case `private`
            case memberCount = "member_count"
            case followerCount = "follower_count"
            case description
            case ownerID = "owner_id"
            case createdAt = "created_at"
        }
    }
}
