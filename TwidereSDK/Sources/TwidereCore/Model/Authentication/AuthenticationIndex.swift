//
//  AuthenticationIndex.swift
//  
//
//  Created by MainasuK on 2022-3-30.
//

import Foundation
import CoreDataStack

extension AuthenticationIndex {
    public var account: UserObject? {
        switch platform {
        case .none:
            return nil
        case .twitter:
            guard let user = twitterAuthentication?.user else { return nil }
            return .twitter(object: user)
        case .mastodon:
            guard let user = mastodonAuthentication?.user else { return nil }
            return .mastodon(object: user)
        }
    }
}
