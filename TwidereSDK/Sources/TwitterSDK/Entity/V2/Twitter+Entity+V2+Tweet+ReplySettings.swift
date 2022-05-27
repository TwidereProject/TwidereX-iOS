//
//  Twitter+Entity+V2+Tweet+ReplySettings.swift
//  
//
//  Created by MainasuK on 2022-5-24.
//

import Foundation

extension Twitter.Entity.V2.Tweet {
    public enum ReplySettings: String, Codable, Hashable, CaseIterable {
        case everyone
        case following
        case mentionedUsers = "mentionedUsers"      // value not has underscore?!
    }
}
