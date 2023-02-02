//
//  AccountListViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/11.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack

final class AccountListViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let authenticationIndexFetchedResultsController: NSFetchedResultsController<AuthenticationIndex>

    // output
    var diffableDataSource: UITableViewDiffableDataSource<UserSection, UserItem>!
    @Published var items: [UserItem] = []
    
    init(
        context: AppContext,
        authContext: AuthContext
    ) {
        self.context = context
        self.authContext = authContext
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
        
        authenticationIndexFetchedResultsController.delegate = self
        try? authenticationIndexFetchedResultsController.performFetch()
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension AccountListViewModel: NSFetchedResultsControllerDelegate {

    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
         os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        switch controller {
        case authenticationIndexFetchedResultsController:
            let authenticationIndexes = authenticationIndexFetchedResultsController.fetchedObjects ?? []
            items = authenticationIndexes.map { authenticationIndex in
                UserItem.authenticationIndex(record: authenticationIndex.asRecrod)
            }
        default:
            assertionFailure()
        }
    }

}
