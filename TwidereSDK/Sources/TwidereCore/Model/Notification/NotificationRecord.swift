//
//  NotificationRecord.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack

public enum NotificationRecord: Hashable {
    case twitter(record: ManagedObjectRecord<TwitterStatus>)
    case mastodon(record: ManagedObjectRecord<MastodonNotification>)
}

extension NotificationRecord {
    public func object(in managedObjectContext: NSManagedObjectContext) -> NotificationObject? {
        switch self {
        case .twitter(let record):
            guard let object = record.object(in: managedObjectContext) else { return nil }
            return .twitter(object: object)
        case .mastodon(let record):
            guard let object = record.object(in: managedObjectContext) else { return nil }
            return .mastodon(object: object)
        }
    }
}

extension NotificationRecord {
    public func status(in managedObjectContext: NSManagedObjectContext) async -> StatusRecord? {
        return await managedObjectContext.perform {
            guard let object = self.object(in: managedObjectContext) else { return nil }
            switch object {
            case .twitter(let object):
                let status = object
                return .twitter(record: status.asRecrod)
            case .mastodon(let object):
                guard let status = object.status else { return nil }
                return .mastodon(record: status.asRecrod)
            }
        }
    }   // end func
}


