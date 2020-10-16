//
//  Twitter+Request+Expansions.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import Foundation

extension Twitter.Request {
    public enum Expansions: String, CaseIterable {
        case attachmentsPollIDs = "attachments.poll_ids"
        case attachmentsMediaKeys = "attachments.media_keys"
        case authorID = "author_id"
        case entitiesMentionsUsername = "entities.mentions.username"
        case geoPlaceID = "geo.place_id"
        case inReplyToUserID = "in_reply_to_user_id"
        case referencedTweetsID = "referenced_tweets.id"
        case referencedTweetsIDAuthorID = "referenced_tweets.id.author_id"
    }
}

extension Collection where Element == Twitter.Request.Expansions {
    public var queryItem: URLQueryItem {
        let value = self.map { $0.rawValue }.joined(separator: ",")
        return URLQueryItem(name: "expansions", value: value)
    }
}
