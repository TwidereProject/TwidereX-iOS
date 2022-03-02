//
//  Twitter+Request+ListFields.swift
//  
//
//  Created by MainasuK on 2022-2-28.
//

import Foundation

extension Twitter.Request {
    public enum ListFields: String, CaseIterable {
        case createdAt = "created_at"
        case followerCount = "follower_count"
        case memberCount = "member_count"
        case `private` = "private"
        case description = "description"
        case ownerID = "owner_id"
    }
}

extension Collection where Element == Twitter.Request.ListFields {
    public var queryItem: URLQueryItem {
        let value = self.map { $0.rawValue }.joined(separator: ",")
        return URLQueryItem(name: "list.fields", value: value)
    }
}
