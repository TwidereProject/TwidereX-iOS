//
//  TwitterListRecordFetchedResultController.swift
//  
//
//  Created by MainasuK on 2022-2-28.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK

final public class TwitterListRecordFetchedResultController: NSObject {
    
    let logger = Logger(subsystem: "TwitterListRecordFetchedResultController", category: "FetchedResultsController")
    
    var disposeBag = Set<AnyCancellable>()
    
    let fetchedResultsController: NSFetchedResultsController<TwitterList>
    
    // input
    @Published var ids: [Twitter.Entity.User.ID] = []
    @Published var predicate: NSPredicate? = nil
    
    // output
    private let _objectIDs = PassthroughSubject<[NSManagedObjectID], Never>()
    @Published public var records: [ManagedObjectRecord<TwitterList>] = []
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.fetchedResultsController = {
            let fetchRequest = TwitterList.sortedFetchRequest
            fetchRequest.predicate = TwitterList.predicate(ids: [])
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
        
        // debounce output to prevent UI update issues
        _objectIDs
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .map { objectIDs in objectIDs.map { ManagedObjectRecord(objectID: $0) } }
            .assign(to: &$records)
        
        fetchedResultsController.delegate = self
        
        Publishers.CombineLatest(
            $ids,
            $predicate
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] ids, predicate in
            guard let self = self else { return }
            
            let compoundPredicate: NSPredicate = {
                if let predicate = predicate {
                    return NSCompoundPredicate(andPredicateWithSubpredicates: [
                        TwitterList.predicate(ids: ids),
                        predicate
                    ])
                } else {
                    return TwitterList.predicate(ids: ids)
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

extension TwitterListRecordFetchedResultController {
    public func reset() {
        ids = []
    }
    
    public func prepend(ids: [TwitterList.ID]) {
        var result = self.ids
        let ids = ids.filter { !result.contains($0) }
        result = ids + result
        self.ids = result
    }
    
    public func append(ids: [TwitterList.ID]) {
        var result = self.ids
        for id in ids where !result.contains(id) {
            result.append(id)
        }
        self.ids = result
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TwitterListRecordFetchedResultController: NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")

        let indexes = ids
        let objects = fetchedResultsController.fetchedObjects ?? []
        
        let objectIDs: [NSManagedObjectID] = objects
            .compactMap { object in
                indexes.firstIndex(of: object.id).map { index in (index, object) }
            }
            .sorted { $0.0 < $1.0 }
            .map { $0.1.objectID }
        self._objectIDs.send(objectIDs)
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch \(objectIDs.count) objects")
    }
}
