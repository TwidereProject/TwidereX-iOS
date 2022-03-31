//
//  Mastodon+Entity+Account.swift
//  
//
//  Created by MainasuK on 2022-3-31.
//

import Foundation
import MastodonSDK

extension Mastodon.Entity.Account {
    public var name: String {
        if displayName.isEmpty {
            return username
        } else {
            return displayName
        }
    }
    
    public func acctWithDomain(domain: String) -> String {
        if !acct.contains("@") {
            // Safe concat due to username cannot contains "@"
            return username + "@" + domain
        } else {
            return acct
        }
    }
}
