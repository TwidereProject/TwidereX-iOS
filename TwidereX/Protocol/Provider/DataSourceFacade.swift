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
    
    private static func redirectStatusRecord(
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
    
    private static func redirectStatus(
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
                guard let objectID = status.repost?.objectID else { return nil }
                return .init(objectID: objectID)
            case .quote:
                assertionFailure("")
                return nil
            }
        }
        return record
    }
    
}

extension DataSourceFacade {
    static func coordinateToStatusThreadScene(
        provider: DataSourceProvider,
        target: StatusTarget,
        status: DataSourceItem.Status
    ) async {
        switch status {
        case .twitter(let record):
            await coordinateToStatusThreadScene(provider: provider, target: target, twitterStatusRecord: record)
        case .mastodon(let record):
            await coordinateToStatusThreadScene(provider: provider, target: target, mastodonStatusRecord: record)
        }
    }
    
    static func coordinateToStatusThreadScene(
        provider: DataSourceProvider,
        target: StatusTarget,
        twitterStatusRecord record: ManagedObjectRecord<TwitterStatus>
    ) async {
        let redirectedRecord = await redirectStatusRecord(
            managedObjectContext: provider.context.managedObjectContext,
            twitterStatusRecord: record,
            target: target
        )
        let _root: StatusItem.Thread? = redirectedRecord.flatMap { StatusItem.Thread.root(status: .twitter(record: $0)) }
        guard let root = _root else {
            assertionFailure()
            return
        }
        let statusThreadViewModel = StatusThreadViewModel(
            context: provider.context,
            root: root
        )
        await provider.coordinator.present(
            scene: .statusThread(viewModel: statusThreadViewModel),
            from: provider,
            transition: .show
        )
    }
    
    static func coordinateToStatusThreadScene(
        provider: DataSourceProvider,
        target: StatusTarget,
        mastodonStatusRecord record: ManagedObjectRecord<MastodonStatus>
    ) async {
        let redirectedRecord = await redirectStatus(
            managedObjectContext: provider.context.managedObjectContext,
            mastodonStatusRecord: record,
            target: target
        )
        let _root: StatusItem.Thread? = redirectedRecord.flatMap { StatusItem.Thread.root(status: .mastodon(record: $0)) }
        guard let root = _root else {
            assertionFailure()
            return
        }
        let statusThreadViewModel = StatusThreadViewModel(
            context: provider.context,
            root: root
        )
        await provider.coordinator.present(
            scene: .statusThread(viewModel: statusThreadViewModel),
            from: provider,
            transition: .show
        )
    }

}
    
    
