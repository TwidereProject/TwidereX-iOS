//
//  SearchMediaViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import CoreData
import CoreDataStack

extension SearchMediaViewModel {
    func setupDiffableDataSource(collectionView: UICollectionView) {
        diffableDataSource = MediaSection.collectionViewDiffableDataSource(
            collectionView: collectionView,
            managedObjectContext: fetchedResultsController.managedObjectContext
        )
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension SearchMediaViewModel: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        guard diffableDataSource != nil else { return }
        let oldSnapshot = diffableDataSource.snapshot()
        
        var oldSnapshotAttributeDict: [NSManagedObjectID : Item.PhotoAttribute] = [:]
        for item in oldSnapshot.itemIdentifiers {
            guard case let .photoTweet(objectID, attribute) = item else { continue }
            oldSnapshotAttributeDict[objectID] = attribute
        }
        
        let tweets = fetchedResultsController.fetchedObjects ?? []
        guard tweets.count == searchMediaTweetIDs.value.count else { return }
        
        var items: [Item] = []
        for tweet in tweets {
            let mediaArray = Array(tweet.media ?? Set())
            let photoMedia = mediaArray.filter { $0.type == "photo" }
            guard !photoMedia.isEmpty else { continue }
            let attribute = oldSnapshotAttributeDict[tweet.objectID] ?? Item.PhotoAttribute(index: 0)
            let item = Item.photoTweet(objectID: tweet.objectID, attribute: attribute)
            items.append(item)
        }
        
        self.items.value = items
    }
}
