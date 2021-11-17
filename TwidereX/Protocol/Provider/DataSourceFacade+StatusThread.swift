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
        status: StatusRecord
    ) async {
        let _redirectRecord = await DataSourceFacade.status(
            managedObjectContext: provider.context.managedObjectContext,
            status: status,
            target: target
        )
        let _root: StatusItem.Thread? = _redirectRecord.flatMap { redirectedRecord in
            switch redirectedRecord {
            case .twitter(let record):
                return StatusItem.Thread.root(status: .twitter(record: record))
            case .mastodon(let record):
                return StatusItem.Thread.root(status: .mastodon(record: record))
            }
        }
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
