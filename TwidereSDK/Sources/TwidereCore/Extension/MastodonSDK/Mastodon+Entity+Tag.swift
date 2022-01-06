//
//  Mastodon+Entity+Tag.swift
//  
//
//  Created by MainasuK on 2022-1-6.
//

import Foundation
import MastodonSDK

extension Mastodon.Entity.Tag {
    
    /// the sum of recent 2 days
    public var talkingPeopleCount: Int? {
        return history?
            .prefix(2)
            .compactMap { Int($0.accounts) }
            .reduce(0, +)
    }
    
}
