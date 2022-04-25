//
//  MastodonMention.swift
//  
//
//  Created by MainasuK on 2022-4-11.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension MastodonMention {
    convenience init(mention: Mastodon.Entity.Mention) {
        self.init(
            id: mention.id,
            username: mention.username,
            url: mention.url,
            acct: mention.acct
        )
    }
}
