//
//  Twitter+Request+UserFields.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import Foundation

extension Twitter.Request {
    public enum UserFields: String, CaseIterable {
        case createdAt = "created_at"
        case description = "description"
        case entities = "entities"
        case id = "id"
        case location = "location"
        case name = "name"
        case pinnedTweetID = "pinned_tweet_id"
        case profileImageURL = "profile_image_url"
        case protected = "protected"
        case publicMetrics = "public_metrics"
        case url = "url"
        case username = "username"
        case verified = "verified"
        case withheld = "withheld"
        
        public static var allCasesQueryItem: URLQueryItem {
            let value = TwitterFields.allCases.map { $0.rawValue }.joined(separator: ",")
            return URLQueryItem(name: "user.fields", value: value)
        }
    }
}
