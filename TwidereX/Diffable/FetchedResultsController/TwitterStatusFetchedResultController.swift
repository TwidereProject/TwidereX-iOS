//
//  TwitterStatusFetchedResultController.swift
//  TwitterStatusFetchedResultController
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK

final class TwitterStatusFetchedResultController: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    let fetchedResultsController: NSFetchedResultsController<TwitterStatus>
    
    // input
    let statusIDs = CurrentValueSubject<[Twitter.Entity.V2.Tweet.ID], Never>([])
    let predicate = CurrentValueSubject<NSPredicate?, Never>(nil)
    
    // output
    private let _objectIDs = PassthroughSubject<[NSManagedObjectID], Never>()
    let records = CurrentValueSubject<[ManagedObjectRecord<TwitterStatus>], Never>([])
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.fetchedResultsController = {
            let fetchRequest = TwitterStatus.sortedFetchRequest
            fetchRequest.predicate = TwitterStatus.predicate(ids: [])
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
            statusIDs,
            predicate
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] statusIDs, predicate in
            guard let self = self else { return }
            
            let compoundPredicate: NSPredicate = {
                if let predicate = predicate {
                    return NSCompoundPredicate(andPredicateWithSubpredicates: [
                        TwitterStatus.predicate(ids: statusIDs),
                        predicate
                    ])
                } else {
                    return TwitterStatus.predicate(ids: statusIDs)
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

extension TwitterStatusFetchedResultController {
    func append(statusIDs: [Twitter.Entity.V2.Tweet.ID]) {
        var result = self.statusIDs.value
        for statusID in statusIDs where !result.contains(statusID) {
            result.append(statusID)
        }
        self.statusIDs.value = result
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TwitterStatusFetchedResultController: NSFetchedResultsControllerDelegate {
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let indexes = statusIDs.value
        let statuses = fetchedResultsController.fetchedObjects ?? []
        
        let objectIDs: [NSManagedObjectID] = statuses
            .compactMap { status in
                indexes.firstIndex(of: status.id).map { index in (index, status) }
            }
            .sorted { $0.0 < $1.0 }
            .map { $0.1.objectID }
        
        self._objectIDs.send(objectIDs)
    }
}
