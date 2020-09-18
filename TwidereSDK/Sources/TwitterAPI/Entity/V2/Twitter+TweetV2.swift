//
//  Twitter+TweetV2.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-15.
//

import Foundation

extension Twitter.Entity {
    public struct TweetV2: Codable {
        
        public typealias ID = String
        
        // Fundamental
        public let id: ID
        public let text: String
        
        public let conversationID: String
        
        public enum CodingKeys: String, CodingKey {
            case id
            case text
            
            case conversationID = "conversation_id"
        }
        
    }
}
