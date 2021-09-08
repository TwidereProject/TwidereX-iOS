//
//  DataSourceFacade+StatusThread.swift
//  DataSourceFacade+StatusThread
//
//  Created by Cirno MainasuK on 2021-9-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack

extension DataSourceFacade {
    static func coordinateToStatusThreadScene(
        provider: DataSourceProvider,
        target: StatusTarget,
        status: DataSourceItem.Status
    ) async {
        switch status {
        case .twitter(let record):
            await coordinateToStatusThreadScene(
                provider: provider,
                target: target,
                twitterStatusRecord: record
            )
        case .mastodon(let record):
            await coordinateToStatusThreadScene(
                provider: provider,
                target: target,
                mastodonStatusRecord: record
            )
        }
    }
    
    private static func coordinateToStatusThreadScene(
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
    
    private static func coordinateToStatusThreadScene(
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
