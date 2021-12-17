//
//  UserRecord.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import CoreData
import CoreDataStack

public enum UserRecord: Hashable {
    case twitter(record: ManagedObjectRecord<TwitterUser>)
    case mastodon(record: ManagedObjectRecord<MastodonUser>)
}

extension UserRecord {
    public init(object: UserObject) {
        switch object {
        case .twitter(let object):
            self = .twitter(record: .init(objectID: object.objectID))
        case .mastodon(let object):
            self = .mastodon(record: .init(objectID: object.objectID))
        }
    }
}

extension UserRecord {
    public func object(in managedObjectContext: NSManagedObjectContext) -> UserObject? {
        switch self {
        case .twitter(let record):
            return record.object(in: managedObjectContext)
                .flatMap { UserObject.twitter(object: $0) }
        case .mastodon(let record):
            return record.object(in: managedObjectContext)
                .flatMap { UserObject.mastodon(object: $0) }
        }
    }
}
