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
        provider: DataSourceProvider & AuthContextProvider,
        target: StatusTarget,
        status: StatusRecord
    ) async {
        let _root: StatusItem.Thread? = await {
            let _redirectRecord = await DataSourceFacade.status(
                managedObjectContext: provider.context.managedObjectContext,
                status: status,
                target: target
            )
            guard let redirectRecord = _redirectRecord else { return nil }

            switch redirectRecord {
            case .twitter(let record):
                let context = StatusItem.Thread.Context(
                    status: .twitter(record: record),
                    displayUpperConversationLink: await provider.context.managedObjectContext.perform {
                        guard let status = record.object(in: provider.context.managedObjectContext) else { return false }
                        return status.replyToStatusID != nil
                    },
                    displayBottomConversationLink: false
                )
                return StatusItem.Thread.root(context: context)
            case .mastodon(let record):
                let context = StatusItem.Thread.Context(
                    status: .mastodon(record: record),
                    displayUpperConversationLink: await provider.context.managedObjectContext.perform {
                        guard let status = record.object(in: provider.context.managedObjectContext) else { return false }
                        return status.replyToStatusID != nil
                    },
                    displayBottomConversationLink: false
                )
                return StatusItem.Thread.root(context: context)
            }
        }()
        guard let root = _root else {
            assertionFailure()
            return
        }
        
        await coordinateToStatusThreadScene(
            provider: provider,
            root: root
        )
    }
    
    @MainActor
    static func coordinateToStatusThreadScene(
        provider: DataSourceProvider & AuthContextProvider,
        root: StatusItem.Thread
    ) async {
        let statusThreadViewModel = StatusThreadViewModel(
            context: provider.context,
            authContext: provider.authContext,
            root: root
        )
        provider.coordinator.present(
            scene: .statusThread(viewModel: statusThreadViewModel),
            from: provider,
            transition: .show
        )
        
        Task {
            guard case let .root(threadContext) = root else { return }
            await recordStatusHistory(
                denpendency: provider,
                status: threadContext.status
            )
        }   // end Task
    }
}
