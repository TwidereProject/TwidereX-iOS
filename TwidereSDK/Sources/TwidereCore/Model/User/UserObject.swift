//
//  UserObject.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import CoreDataStack

public enum UserObject: Hashable {
    case twitter(object: TwitterUser)
    case mastodon(object: MastodonUser)
}
