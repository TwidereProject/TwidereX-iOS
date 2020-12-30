//
//  OrderedTwitterUserFetchedResultsController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterAPI

final class OrderedTwitterUserFetchedResultsController: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    let fetchedResultsController: NSFetchedResultsController<TwitterUser>
    
    // input
    let userIDs = CurrentValueSubject<[Twitter.Entity.User.ID], Never>([])
    
    // output
    let items = CurrentValueSubject<[Item], Never>([])
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.fetchedResultsController = {
            let fetchRequest = TwitterUser.sortedFetchRequest
            fetchRequest.predicate = TwitterUser.predicate(idStrs: [])
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
        
        fetchedResultsController.delegate = self
        
        userIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ids in
                guard let self = self else { return }
                self.fetchedResultsController.fetchRequest.predicate = TwitterUser.predicate(idStrs: ids)
                do {
                    try self.fetchedResultsController.performFetch()
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
            .store(in: &disposeBag)
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension OrderedTwitterUserFetchedResultsController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let indexes = userIDs.value
        let twitterUsers = fetchedResultsController.fetchedObjects ?? []
        guard twitterUsers.count == indexes.count else { return }
        
        let items: [Item] = twitterUsers
            .compactMap { twitterUser in
                indexes.firstIndex(of: twitterUser.id).map { index in (index, twitterUser) }
            }
            .sorted { $0.0 < $1.0 }
            .map { Item.twitterUser(objectID: $0.1.objectID) }
        self.items.value = items
    }
}
