//
//  ListRecord.swift
//  
//
//  Created by MainasuK on 2022-2-28.
//

import CoreData
import CoreDataStack

public enum ListRecord: Hashable {
    case twitter(record: ManagedObjectRecord<TwitterList>)
    case mastodon(record: ManagedObjectRecord<MastodonList>)
}

extension ListRecord {
    public init(object: ListObject) {
        switch object {
        case .twitter(let object):
            self = .twitter(record: .init(objectID: object.objectID))
        case .mastodon(let object):
            self = .mastodon(record: .init(objectID: object.objectID))
        }
    }
}

extension ListRecord {
    public func object(in managedObjectContext: NSManagedObjectContext) -> ListObject? {
        switch self {
        case .twitter(let record):
            return record.object(in: managedObjectContext)
                .flatMap { ListObject.twitter(object: $0) }
        case .mastodon(let record):
            return record.object(in: managedObjectContext)
                .flatMap { ListObject.mastodon(object: $0) }
        }
    }
}
