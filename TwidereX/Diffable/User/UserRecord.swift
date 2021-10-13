//
//  UserRecord.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import CoreDataStack

enum UserRecord: Hashable {
    case twitter(record: ManagedObjectRecord<TwitterUser>)
    case mastodon(record: ManagedObjectRecord<MastodonUser>)
}
