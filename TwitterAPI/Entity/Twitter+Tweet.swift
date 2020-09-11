//
//  Twitter+Tweet.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation

extension Twitter.Entity {
    public class Tweet: Codable {

        // Fundamental
        public let createdAt: Date
        public let idStr: String
        public let text: String

        public let user: User
        public let entities: Entities
        public let extendedEntities: ExtendedEntities?
        
        public let place: Place?

        //let contributors: JSONNull?
        //let coordinates: Coordinates?
        //let extendedEntities: TimelineExtendedEntities?
        public let favoriteCount: Int?
        public let favorited: Bool?
        //let geo: Coordinates?
        //let inReplyToScreenName: JSONNull?
        //let inReplyToStatusID: JSONNull?
        //let inReplyToStatusIDStr: JSONNull?
        //let inReplyToUserID: JSONNull?
        //let inReplyToUserIDStr: JSONNull?
        //let isQuoteStatus: Bool
        //let lang: Lang
        //let possiblySensitive: Bool?
        //let possiblySensitiveAppealable: Bool?
        public let retweetCount: Int?
        public let retweeted: Bool?
        public let retweetedStatus: RetweetedStatus?
        
        public let quotedStatusIDStr: String?
        public let quotedStatus: QuotedStatus?
        
        //let source: String
        //let truncated: Bool
        
        public enum CodingKeys: String, CodingKey {
            // Fundamental
            case createdAt = "created_at"
            case idStr = "id_str"
            case text = "text"
            
            case user = "user"
            case entities = "entities"
            case extendedEntities = "extended_entities"
            
            case place = "place"

            //case contributors = "contributors"
            //case coordinates = "coordinates"
            case favoriteCount = "favorite_count"
            case favorited = "favorited"
            //case geo = "geo"
            //case inReplyToScreenName = "in_reply_to_screen_name"
            //case inReplyToStatusID = "in_reply_to_status_id"
            //case inReplyToStatusIDStr = "in_reply_to_status_id_str"
            //case inReplyToUserID = "in_reply_to_user_id"
            //case inReplyToUserIDStr = "in_reply_to_user_id_str"
            //case isQuoteStatus = "is_quote_status"
            //case lang = "lang"
            //case possiblySensitive = "possibly_sensitive"
            //case possiblySensitiveAppealable = "possibly_sensitive_appealable"
            case retweetCount = "retweet_count"
            case retweeted = "retweeted"
            case retweetedStatus = "retweeted_status"
            case quotedStatusIDStr = "quoted_status_id_str"
            case quotedStatus = "quoted_status"
            //case source = "source"
            //case truncated = "truncated"
        }
    }
}
