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
    @MainActor
    static func coordinateToStatusThreadScene(
        provider: DataSourceProvider & AuthContextProvider,
        kind: StatusThreadViewModel.Kind
    ) async {
        let statusThreadViewModel = StatusThreadViewModel(
            context: provider.context,
            authContext: provider.authContext,
            kind: kind
        )
        provider.coordinator.present(
            scene: .statusThread(viewModel: statusThreadViewModel),
            from: provider,
            transition: .show
        )
        
        // FIXME: 
//        Task {
//            guard case let .root(threadContext) = root else { return }
//            await recordStatusHistory(
//                denpendency: provider,
//                status: threadContext.status
//            )
//        }   // end Task
    }
}
