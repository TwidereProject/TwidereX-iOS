//
//  StatusHistoryFetchedResultsController.swift
//  
//
//  Created by MainasuK on 2022-7-29.
//

import os.log
import Foundation
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK
import OrderedCollections

final public class StatusHistoryFetchedResultsController: NSObject {
    
    public let logger = Logger(subsystem: "StatusHistoryFetchedResultsController", category: "DB")
    
    var disposeBag = Set<AnyCancellable>()
    
    public let fetchedResultsController: NSFetchedResultsController<History>
    
    // input
    @Published public var predicate: NSPredicate
    
    // output
    @Published public var groupedRecords: [(String, [ManagedObjectRecord<History>])] = []
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.fetchedResultsController = {
            let fetchRequest = History.sortedFetchRequest
            // make sure initial query return empty results
            fetchRequest.predicate = History.statusPredicate(acct: .none)
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.shouldRefreshRefetchedObjects = true
            fetchRequest.fetchBatchSize = 15
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: managedObjectContext,
                sectionNameKeyPath: #keyPath(History.sectionIdentifierByDay),
                cacheName: nil
            )
            
            return controller
        }()
        self.predicate = History.statusPredicate(acct: .none)
        super.init()
        
        fetchedResultsController.delegate = self
        
        $predicate.removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] predicate in
                guard let self = self else { return }
                self.fetchedResultsController.fetchRequest.predicate = predicate
                do {
                    try self.fetchedResultsController.performFetch()
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension StatusHistoryFetchedResultsController: NSFetchedResultsControllerDelegate {
    public func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        var groupedRecords: [(String, [ManagedObjectRecord<History>])] = []
        for sectionInfo in controller.sections ?? [] {
            guard let objects = sectionInfo.objects as? [History] else { return }
            let identifier = sectionInfo.name
            let records = objects.map { $0.asRecrod }
            groupedRecords.append((identifier, records))
        }
        self.groupedRecords = groupedRecords
    }
}

