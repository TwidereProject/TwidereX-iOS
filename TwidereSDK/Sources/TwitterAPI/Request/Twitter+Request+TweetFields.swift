//
//  Twitter+Request+TweetFields.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-15.
//

import Foundation

extension Twitter.Request {
    public enum TwitterFields: String, CaseIterable {
        case attachments = "attachments"
        case authorID = "author_id"
        case contextAnnotations = "context_annotations"
        case conversationID = "conversation_id"
        case created_at = "created_at"
        case entities = "entities"
        case geo = "geo"
        case id = "id"
        case inReplyToUserID = "in_reply_to_user_id"
        case lang = "lang"
        case nonPublicMetrics = "non_public_metrics"
        case publicMetrics = "public_metrics"
        case organicMetrics = "organic_metrics"
        case promotedMetrics = "promoted_metrics"
        case possiblySensitive = "possibly_sensitive"
        case referencedTweets = "referenced_tweets"
        case source = "source"
        case text = "text"
        case withheld = "withheld"
    }
}

extension Collection where Element == Twitter.Request.TwitterFields {
    public var queryItem: URLQueryItem {
        let value = self.map { $0.rawValue }.joined(separator: ",")
        return URLQueryItem(name: "tweet.fields", value: value)
    }
}
