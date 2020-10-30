//
//  SearchMediaViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import CoreData
import CoreDataStack

extension SearchMediaViewModel {
    func setupDiffableDataSource(collectionView: UICollectionView) {
        diffableDataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item -> UICollectionViewCell? in
            guard let self = self else { return nil }
            switch item {
            case .photo(let objectID, let attribute):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: SearchMediaCollectionViewCell.self), for: indexPath) as! SearchMediaCollectionViewCell
                self.fetchedResultsController.managedObjectContext.performAndWait {
                    let tweet = self.fetchedResultsController.managedObjectContext.object(with: objectID) as! Tweet
                    let media = Array(tweet.media ?? Set()).sorted(by: { $0.index.compare($1.index) == .orderedAscending })
                    if media.isEmpty {
                        // assertionFailure()
                    } else {
                        var snapshot = NSDiffableDataSourceSnapshot<SearchMediaCollectionViewCell.Section, SearchMediaCollectionViewCell.Item>()
                        snapshot.appendSections([.main])
                        let items = media.compactMap { element -> SearchMediaCollectionViewCell.Item? in
                            guard element.type == "photo" else { return nil }
                            guard let url = element.photoURL(sizeKind: .small)?.0 else { return nil }
                            return SearchMediaCollectionViewCell.Item.preview(url: url)
                        }
                        snapshot.appendItems(items, toSection: .main)
                        cell.diffableDataSource.apply(snapshot, animatingDifferences: false)
                    }
                }
                // TODO: use attribute control preview position
                return cell
            case .bottomLoader:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ActivityIndicatorCollectionViewCell.self), for: indexPath) as! ActivityIndicatorCollectionViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            }
        }
    }
}

extension SearchMediaViewModel {
    
    enum SearchMediaSection: Int {
        case main
        case loader
    }
    
    enum SearchMediaItem {
        case photo(tweetObjectID: NSManagedObjectID, attribute: PhotoAttribute)
        case bottomLoader
    }

}

extension SearchMediaViewModel.SearchMediaItem: Hashable {
    
    static func == (lhs: SearchMediaViewModel.SearchMediaItem, rhs: SearchMediaViewModel.SearchMediaItem) -> Bool {
        switch (lhs, rhs) {
        case (.photo(let objectIDLeft, let attributeLeft), .photo(let objectIDRight, let attributeRight)):
            return objectIDLeft == objectIDRight && attributeLeft.index == attributeRight.index
        case (.bottomLoader, bottomLoader):
            return true
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .photo(let objectID, let attribute):
            hasher.combine(objectID)
        case .bottomLoader:
            hasher.combine(String(describing: SearchMediaViewModel.SearchMediaItem.bottomLoader.self))
        }
    }
    
}

extension SearchMediaViewModel.SearchMediaItem {
    class PhotoAttribute: Hashable {
        let id = UUID()
        let index: Int

        public init(index: Int) {
            self.index = index
        }
        
        static func == (lhs: SearchMediaViewModel.SearchMediaItem.PhotoAttribute, rhs: SearchMediaViewModel.SearchMediaItem.PhotoAttribute) -> Bool {
            return lhs.index == rhs.index
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
