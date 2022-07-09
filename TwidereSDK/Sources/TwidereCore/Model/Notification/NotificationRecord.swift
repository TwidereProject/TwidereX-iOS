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
    case mastodon(record: ManagedObjectRecord<MastodonNotification>)
}

extension NotificationRecord {
    public func object(in managedObjectContext: NSManagedObjectContext) -> NotificationObject? {
        switch self {
        case .mastodon(let record):
            guard let notification = record.object(in: managedObjectContext) else { return nil }
            return .mastodon(object: notification)
        }
    }
}

extension NotificationRecord {
    public func status(in managedObjectContext: NSManagedObjectContext) async -> StatusRecord? {
        return await managedObjectContext.perform {
            guard let object = self.object(in: managedObjectContext) else { return nil }
            switch object {
            case .mastodon(let object):
                guard let objectID = object.status?.objectID else { return nil }
                return .mastodon(record: .init(objectID: objectID))
            }
        }
    }   // end func
}


