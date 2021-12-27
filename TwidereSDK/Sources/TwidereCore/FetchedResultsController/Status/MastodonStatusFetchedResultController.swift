//
//  MastodonStatusFetchedResultController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

final public class MastodonStatusFetchedResultController: NSObject {
    
    let logger = Logger(subsystem: "MastodonStatusFetchedResultController", category: "DB")
    
    var disposeBag = Set<AnyCancellable>()
    
    public let fetchedResultsController: NSFetchedResultsController<MastodonStatus>
    
    // input
    public let domain = CurrentValueSubject<String, Never>("")
    public let statusIDs = CurrentValueSubject<[Mastodon.Entity.Status.ID], Never>([])
    public let predicate = CurrentValueSubject<NSPredicate?, Never>(nil)
    
    // output
    private let _objectIDs = PassthroughSubject<[NSManagedObjectID], Never>()
    public let records = CurrentValueSubject<[ManagedObjectRecord<MastodonStatus>], Never>([])
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.fetchedResultsController = {
            let fetchRequest = MastodonStatus.sortedFetchRequest
            fetchRequest.predicate = MastodonStatus.predicate(domain: "", ids: [])
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
        
        Publishers.CombineLatest3(
            domain,
            statusIDs,
            predicate
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] domain, statusIDs, predicate in
            guard let self = self else { return }
            
            let compoundPredicate: NSPredicate = {
                if let predicate = predicate {
                    return NSCompoundPredicate(andPredicateWithSubpredicates: [
                        MastodonStatus.predicate(domain: domain, ids: statusIDs),
                        predicate
                    ])
                } else {
                    return MastodonStatus.predicate(domain: domain, ids: statusIDs)
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

extension MastodonStatusFetchedResultController {
    public func append(statusIDs: [Mastodon.Entity.Status.ID]) {
        var result = self.statusIDs.value
        for statusID in statusIDs where !result.contains(statusID) {
            result.append(statusID)
        }
        self.statusIDs.value = result
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension MastodonStatusFetchedResultController: NSFetchedResultsControllerDelegate {
    public func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        let indexes = statusIDs.value
        let statuses = fetchedResultsController.fetchedObjects ?? []
        
        let objectIDs: [NSManagedObjectID] = statuses
            .compactMap { status in
                indexes.firstIndex(of: status.id).map { index in (index, status) }
            }
            .sorted { $0.0 < $1.0 }
            .map { $0.1.objectID }
        
        self._objectIDs.send(objectIDs)
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch \(objectIDs.count) objects")
    }
}
