//
//  StatusRecord.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import CoreData

enum StatusRecord: Hashable {
    case twitter(record: ManagedObjectRecord<TwitterStatus>)
    case mastodon(record: ManagedObjectRecord<MastodonStatus>)
}

extension StatusRecord {
    func object(in managedObjectContext: NSManagedObjectContext) -> StatusObject? {
        switch self {
        case .twitter(let record):
            guard let status = record.object(in: managedObjectContext) else { return nil }
            return .twitter(object: status)
        case .mastodon(let record):
            guard let status = record.object(in: managedObjectContext) else { return nil }
            return .mastodon(object: status)
        }
    }
}
