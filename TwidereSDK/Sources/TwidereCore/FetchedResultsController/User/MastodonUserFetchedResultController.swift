//
//  MastodonUserFetchedResultController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

final public class MastodonUserFetchedResultController: NSObject {

    let logger = Logger(subsystem: "MastodonStatusFetchedResultController", category: "DB")
    
    var disposeBag = Set<AnyCancellable>()
    
    let fetchedResultsController: NSFetchedResultsController<MastodonUser>

    // input
    @Published public var domain = ""
    @Published public var userIDs: [Mastodon.Entity.Account.ID] = []
    @Published public var predicate: NSPredicate? = nil
    
    // output
    private let _objectIDs = PassthroughSubject<[NSManagedObjectID], Never>()
    @Published public var records: [ManagedObjectRecord<MastodonUser>] = []
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.fetchedResultsController = {
            let fetchRequest = MastodonUser.sortedFetchRequest
            fetchRequest.predicate = MastodonUser.predicate(domain: "", ids: [])
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
            .assign(to: &$records)
            
        fetchedResultsController.delegate = self

        Publishers.CombineLatest3(
            $domain,
            $userIDs,
            $predicate
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] domain, userIDs, predicate in
            guard let self = self else { return }
            
            let compoundPredicate: NSPredicate = {
                if let predicate = predicate {
                    return NSCompoundPredicate(andPredicateWithSubpredicates: [
                        MastodonUser.predicate(domain: domain, ids: userIDs),
                        predicate
                    ])
                } else {
                    return MastodonUser.predicate(domain: domain, ids: userIDs)
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

extension MastodonUserFetchedResultController {
    public func prepend(userIDs: [Mastodon.Entity.Account.ID]) {
        var result = self.userIDs
        let userIDs = userIDs.filter { !result.contains($0) }
        result = userIDs + result
        self.userIDs = result
    }
    
    public func append(userIDs: [Mastodon.Entity.Account.ID]) {
        var result = self.userIDs
        for statusID in userIDs where !result.contains(statusID) {
            result.append(statusID)
        }
        self.userIDs = result
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension MastodonUserFetchedResultController: NSFetchedResultsControllerDelegate {
    public func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        let indexes = userIDs
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
