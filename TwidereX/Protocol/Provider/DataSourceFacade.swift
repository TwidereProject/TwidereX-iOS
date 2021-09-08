//
//  DataSourceFacade.swift
//  DataSourceFacade
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack

enum DataSourceFacade {
    enum StatusTarget {
        case status         // remove repost wrapper
        case repost         // keep repost wrapper
        case quote          // remove repost wrapper then locate to quote
    }
    
    static func redirectStatusRecord(
        managedObjectContext: NSManagedObjectContext,
        twitterStatusRecord record: ManagedObjectRecord<TwitterStatus>,
        target: StatusTarget
    ) async -> ManagedObjectRecord<TwitterStatus>? {
        let record: ManagedObjectRecord<TwitterStatus>? = await managedObjectContext.perform {
            guard let status = record.object(in: managedObjectContext) else { return nil }
            switch target {
            case .status:
                let objectID = (status.repost ?? status).objectID
                return .init(objectID: objectID)
            case .repost:
                let objectID = status.objectID
                return .init(objectID: objectID)
            case .quote:
                guard let objectID = (status.repost?.quote ?? status.quote)?.objectID else { return nil }
                return .init(objectID: objectID)
            }
        }
        return record
    }
    
    static func redirectStatus(
        managedObjectContext: NSManagedObjectContext,
        mastodonStatusRecord record: ManagedObjectRecord<MastodonStatus>,
        target: StatusTarget
    ) async -> ManagedObjectRecord<MastodonStatus>? {
        let record: ManagedObjectRecord<MastodonStatus>? = await managedObjectContext.perform {
            guard let status = record.object(in: managedObjectContext) else { return nil }
            switch target {
            case .status:
                let objectID = (status.repost ?? status).objectID
                return .init(objectID: objectID)
            case .repost:
                let objectID = status.objectID
                return .init(objectID: objectID)
            case .quote:
                assertionFailure("")
                return nil
            }
        }
        return record
    }
    
}

