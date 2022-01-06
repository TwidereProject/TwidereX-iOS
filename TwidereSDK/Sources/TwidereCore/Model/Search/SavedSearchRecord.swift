//
//  SavedSearchRecord.swift
//  
//
//  Created by MainasuK on 2021-12-22.
//

import Foundation
import CoreData
import CoreDataStack

public enum SavedSearchRecord: Hashable {
    case twitter(record: ManagedObjectRecord<TwitterSavedSearch>)
    case mastodon(record: ManagedObjectRecord<MastodonSavedSearch>)
}

extension SavedSearchRecord {
    public func object(in managedObjectContext: NSManagedObjectContext) -> SavedSearchObject? {
        switch self {
        case .twitter(let record):
            guard let object = record.object(in: managedObjectContext) else { return nil }
            return .twitter(object: object)
        case .mastodon(let record):
            guard let object = record.object(in: managedObjectContext) else { return nil }
            return .mastodon(object: object)
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
