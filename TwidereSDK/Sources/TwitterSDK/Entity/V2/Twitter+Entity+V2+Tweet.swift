//
//  Twitter+Entity+V2+Tweet.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-15.
//

import Foundation

extension Twitter.Entity.V2 {
    public struct Tweet: Codable, Identifiable {
        
        public typealias ID = String
        public typealias ConversationID = String
        
        // Fundamental
        public let id: ID
        public let text: String
        
        // Extra
        public let attachments: Attachments?
        public let authorID: String?
        // public let contextAnnotations
        public let conversationID: ConversationID?
        public let createdAt: Date      // client required
        public let entities: Entities?
        public let geo: Geo?
        public let inReplyToUserID: User.ID?
        public let lang: String?
        public let publicMetrics: PublicMetrics?
        public let possiblySensitive: Bool?
        public let referencedTweets: [ReferencedTweet]?
        public let replySettings: ReplySettings?
        public let source: String?
        public let withheld: Withheld?
        
        public enum CodingKeys: String, CodingKey {
            case id
            case text
            
            case attachments
            case authorID = "author_id"
            //case context_annotations
            case conversationID = "conversation_id"
            case createdAt = "created_at"
            case entities
            case inReplyToUserID = "in_reply_to_user_id"
            case geo
            case lang
            case publicMetrics = "public_metrics"
            case possiblySensitive = "possibly_sensitive"
            case referencedTweets = "referenced_tweets"
            case replySettings = "reply_settings"
            case source
            case withheld
        }
        
    }
}


