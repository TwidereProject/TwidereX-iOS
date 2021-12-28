//
//  TwitterSavedSearchFetchedResultController.swift
//  
//
//  Created by MainasuK on 2021-12-22.
//

import os.log
import Foundation
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK

public final class TwitterSavedSearchFetchedResultController: NSObject {
    
    let logger = Logger(subsystem: "TwitterSavedSearchFetchedResultController", category: "FetchedResultController")
    
    var disposeBag = Set<AnyCancellable>()

    let fetchedResultsController: NSFetchedResultsController<TwitterSavedSearch>

    // input
    @Published public var userID: TwitterUser.ID = ""
    
    // output
    private let _objectIDs = PassthroughSubject<[NSManagedObjectID], Never>()
    public let records = CurrentValueSubject<[ManagedObjectRecord<TwitterSavedSearch>], Never>([])
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.fetchedResultsController = {
            let fetchRequest = TwitterSavedSearch.sortedFetchRequest
            fetchRequest.predicate = TwitterSavedSearch.predicate(userID: "")
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
        
        $userID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userID in
                guard let self = self else { return }
                let predicate = TwitterSavedSearch.predicate(userID: userID)
                self.fetchedResultsController.fetchRequest.predicate = predicate
                
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
extension TwitterSavedSearchFetchedResultController: NSFetchedResultsControllerDelegate {
    public func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        let objects = fetchedResultsController.fetchedObjects ?? []
        let objectIDs: [NSManagedObjectID] = objects.map { $0.objectID }
        self._objectIDs.send(objectIDs)
    }
}
