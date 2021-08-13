//
//  DeletedTweetFetchedResultsController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK

final class TweetFetchedResultsController: NSObject {

    var disposeBag = Set<AnyCancellable>()

    let fetchedResultsController: NSFetchedResultsController<Tweet>

    // input
    let tweetIDs = CurrentValueSubject<[Twitter.Entity.V2.Tweet.ID], Never>([])
    
    // output
    let items = CurrentValueSubject<[Item], Never>([])
    
    init(managedObjectContext: NSManagedObjectContext, additionalTweetPredicate: NSPredicate) {
        self.fetchedResultsController = {
            let fetchRequest = Tweet.sortedFetchRequest
            fetchRequest.predicate = Tweet.predicate(idStrs: [])
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
        
        tweetIDs
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] ids in
                guard let self = self else { return }
                self.fetchedResultsController.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    Tweet.predicate(idStrs: ids),
                    additionalTweetPredicate
                ])
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
extension TweetFetchedResultsController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let indexes = tweetIDs.value
        let tweets = fetchedResultsController.fetchedObjects ?? []
        
        let items: [Item] = tweets
            .compactMap { tweet in
                indexes.firstIndex(of: tweet.id).map { index in (index, tweet) }
            }
            .sorted { $0.0 < $1.0 }
            .map { Item.tweet(objectID: $0.1.objectID) }
        self.items.value = items
    }
}
