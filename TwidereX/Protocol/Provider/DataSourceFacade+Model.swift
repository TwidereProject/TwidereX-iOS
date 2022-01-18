//
//  DataSourceFacade+Model.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-7.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack

extension DataSourceFacade {
    static func status(
        managedObjectContext: NSManagedObjectContext,
        status: StatusRecord,
        target: StatusTarget
    ) async -> StatusRecord? {
        return await managedObjectContext.perform {
            switch status {
            case .twitter(let record):
                guard let object = record.object(in: managedObjectContext) else { return nil }
                return DataSourceFacade.status(status: object, target: target)
                    .flatMap { ManagedObjectRecord<TwitterStatus>(objectID: $0.objectID) }
                    .flatMap { StatusRecord.twitter(record: $0) }
            case .mastodon(let record):
                guard let object = record.object(in: managedObjectContext) else { return nil }
                return DataSourceFacade.status(status: object, target: target)
                    .flatMap { ManagedObjectRecord<MastodonStatus>(objectID: $0.objectID) }
                    .flatMap { StatusRecord.mastodon(record: $0) }
            }
        }
    }
}

extension DataSourceFacade {
    static func author(
        managedObjectContext: NSManagedObjectContext,
        status: StatusRecord,
        target: StatusTarget
    ) async -> UserRecord? {
        return await managedObjectContext.perform {
            switch status {
            case .twitter(let record):
                guard let object = record.object(in: managedObjectContext) else { return nil }
                return DataSourceFacade.status(status: object, target: target)
                    .flatMap { $0.author }
                    .flatMap { ManagedObjectRecord<TwitterUser>(objectID: $0.objectID) }
                    .flatMap { UserRecord.twitter(record: $0) }
            case .mastodon(let record):
                guard let object = record.object(in: managedObjectContext) else { return nil }
                return DataSourceFacade.status(status: object, target: target)
                    .flatMap { $0.author }
                    .flatMap { ManagedObjectRecord<MastodonUser>(objectID: $0.objectID) }
                    .flatMap { UserRecord.mastodon(record: $0) }
            }
        }
    }
}

extension DataSourceFacade {
    static func status(
        status: TwitterStatus,
        target: StatusTarget
    ) -> TwitterStatus? {
        switch target {
        case .status:
            return status.repost ?? status
        case .repost:
            return status
        case .quote:
            return status.quote
        }
    }
    
    static func status(
        status: MastodonStatus,
        target: StatusTarget
    ) -> MastodonStatus? {
        switch target {
        case .status:
            return status.repost ?? status
        case .repost:
            return status
        case .quote:
            assertionFailure()
            return nil
        }
    }
}
