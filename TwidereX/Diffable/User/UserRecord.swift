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

extension UserRecord {
    init(object: UserObject) {
        switch object {
        case .twitter(let object):
            self = .twitter(record: .init(objectID: object.objectID))
        case .mastodon(let object):
            self = .mastodon(record: .init(objectID: object.objectID))
        }
    }
}
