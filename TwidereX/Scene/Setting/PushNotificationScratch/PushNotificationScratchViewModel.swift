//
//  PushNotificationScratchViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-18.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import CoreData
import CoreDataStack
import TwidereCore

final class PushNotificationScratchViewModel: NSObject, ObservableObject {
    
    // input
    let context: AppContext
    let authenticationIndexFetchedResultsController: NSFetchedResultsController<AuthenticationIndex>
    
    @Published var isRandomNotification = true
    @Published var notificationID = ""
    
    // output
    @Published var accounts: [UserObject] = []
    @Published var activeAccountIndex: Int = 0
        
    init(context: AppContext) {
        self.context = context
        self.authenticationIndexFetchedResultsController = {
            let fetchRequest = AuthenticationIndex.sortedFetchRequest
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchBatchSize = 20
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context.managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            return controller
        }()
        super.init()
        // end init
        
        authenticationIndexFetchedResultsController.delegate = self
        try? authenticationIndexFetchedResultsController.performFetch()
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension PushNotificationScratchViewModel: NSFetchedResultsControllerDelegate {

    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
         os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        switch controller {
        case authenticationIndexFetchedResultsController:
            let authenticationIndexes = authenticationIndexFetchedResultsController.fetchedObjects ?? []
            accounts = authenticationIndexes.compactMap { authenticationIndex in
                authenticationIndex.user
            }
        default:
            assertionFailure()
        }
    }

}
