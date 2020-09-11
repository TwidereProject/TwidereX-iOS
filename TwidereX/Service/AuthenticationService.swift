//
//  AuthenticationService.swift
//  TwidereX
//
//  Created by jk234ert on 8/7/20.
//  Copyright © 2020 Dimension. All rights reserved.
//

import Foundation
import Combine
import CoreData
import CoreDataStack

class AuthenticationService: NSObject {
    
    // input
    let managedObjectContext: NSManagedObjectContext
    let twitterAuthenticationFetchedResultsController: NSFetchedResultsController<TwitterAuthentication>

    // output
    let twitterAuthentications = CurrentValueSubject<[TwitterAuthentication], Never>([])
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.twitterAuthenticationFetchedResultsController = {
            let fetchRequest = TwitterAuthentication.sortedFetchRequest
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchBatchSize = 20
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            return controller
        }()
        super.init()
        
        twitterAuthenticationFetchedResultsController.delegate = self
        do {
            try twitterAuthenticationFetchedResultsController.performFetch()
            twitterAuthentications.value = twitterAuthenticationFetchedResultsController.fetchedObjects ?? []
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension AuthenticationService: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // FIXME:
        twitterAuthentications.value = controller.fetchedObjects?.compactMap { $0 as? TwitterAuthentication } ?? []
    }
}
