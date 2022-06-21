//
//  PollOptionRecord.swift
//  
//
//  Created by MainasuK on 2022-6-10.
//

import Foundation
import CoreData
import CoreDataStack

public enum PollOptionRecord: Hashable {
    case twitter(record: ManagedObjectRecord<TwitterPollOption>)
    case mastodon(record: ManagedObjectRecord<MastodonPollOption>)
}

extension PollOptionRecord {
    public func object(in managedObjectContext: NSManagedObjectContext) -> PollOptionObject? {
        switch self {
        case .twitter(let record):
            guard let status = record.object(in: managedObjectContext) else { return nil }
            return .twitter(object: status)
        case .mastodon(let record):
            guard let status = record.object(in: managedObjectContext) else { return nil }
            return .mastodon(object: status)
        }
    }
    
    public var objectID: NSManagedObjectID {
        switch self {
        case .twitter(let record):
            return record.objectID
        case .mastodon(let record):
            return record.objectID
        }
    }
}
