//
//  StatusObject.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import CoreDataStack

enum StatusObject: Hashable {
    case twitter(object: TwitterStatus)
    case mastodon(object: MastodonStatus)
}
