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
        public typealias ConversationID = String
        
        // Fundamental
        public let id: ID
        public let text: String
        
        // Extra
        // tweet.fields:attachments,author_id,context_annotations,conversation_id
        // public let attachments
        public let authorID: String?
        // public let context_annotations
        public let conversationID: ConversationID?
        
        public enum CodingKeys: String, CodingKey {
            case id
            case text
            
            case authorID = "author_id"
            case conversationID = "conversation_id"
        }
        
    }
}
