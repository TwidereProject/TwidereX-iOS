//
//  Feed+Acct.swift
//  Feed+Acct
//
//  Created by Cirno MainasuK on 2021-8-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

extension Feed {
    public enum Acct {
        case twitter(userID: TwitterUser.ID)
        case mastodon(domain: String, userID: MastodonUser.ID)
        
        public var value: String {
            switch self {
            case .twitter(let userID):
                return "\(userID)@twitter.com"
            case .mastodon(let domain, let userID):
                return "\(userID)@\(domain)"
            }
        }
    }
}
