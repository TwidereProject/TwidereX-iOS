//
//  UserIdentifier.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack

enum UserIdentifier: Hashable {
    case twitter(TwitterUserIdentifier)
    case mastodon(MastodonUserIdentifier)
}

struct TwitterUserIdentifier: Hashable {
    let id: TwitterUser.ID
}

struct MastodonUserIdentifier: Hashable {
    let domain: String
    let id: MastodonUser.ID
}
