//
//  TwitterUserFetchedResultsController.swift
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
import TwitterSDK

final class TwitterUserFetchedResultsController: NSObject {
    
    let logger = Logger(subsystem: "TwitterUserFetchedResultsController", category: "ViewController")
    
    var disposeBag = Set<AnyCancellable>()
    
    let fetchedResultsController: NSFetchedResultsController<TwitterUser>
    
    // input
    let userIDs = CurrentValueSubject<[Twitter.Entity.User.ID], Never>([])
    let predicate = CurrentValueSubject<NSPredicate?, Never>(nil)
    
    // output
    private let _objectIDs = PassthroughSubject<[NSManagedObjectID], Never>()
    let records = CurrentValueSubject<[ManagedObjectRecord<TwitterUser>], Never>([])
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.fetchedResultsController = {
            let fetchRequest = TwitterUser.sortedFetchRequest
            fetchRequest.predicate = TwitterUser.predicate(ids: [])
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchBatchSize = 15
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            return controller
        }()
        super.init()
        
        // debounce output to prevent UI update issues
        _objectIDs
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .map { objectIDs in objectIDs.map { ManagedObjectRecord(objectID: $0) } }
            .assign(to: \.value, on: records)
            .store(in: &disposeBag)
        
        fetchedResultsController.delegate = self
        
        Publishers.CombineLatest(
            userIDs,
            predicate
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] userIDs, predicate in
            guard let self = self else { return }
            
            let compoundPredicate: NSPredicate = {
                if let predicate = predicate {
                    return NSCompoundPredicate(andPredicateWithSubpredicates: [
                        TwitterUser.predicate(ids: userIDs),
                        predicate
                    ])
                } else {
                    return TwitterUser.predicate(ids: userIDs)
                }
            }()
            self.fetchedResultsController.fetchRequest.predicate = compoundPredicate
            
            do {
                try self.fetchedResultsController.performFetch()
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
        .store(in: &disposeBag)
    }
    
}

extension TwitterUserFetchedResultsController {
    func append(userIDs: [TwitterUser.ID]) {
        var result = self.userIDs.value
        for statusID in userIDs where !result.contains(statusID) {
            result.append(statusID)
        }
        self.userIDs.value = result
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TwitterUserFetchedResultsController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")

        let indexes = userIDs.value
        let users = fetchedResultsController.fetchedObjects ?? []
        
        let objectIDs: [NSManagedObjectID] = users
            .compactMap { user in
                indexes.firstIndex(of: user.id).map { index in (index, user) }
            }
            .sorted { $0.0 < $1.0 }
            .map { $0.1.objectID }
        self._objectIDs.send(objectIDs)
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch \(objectIDs.count) objects")
    }
}
