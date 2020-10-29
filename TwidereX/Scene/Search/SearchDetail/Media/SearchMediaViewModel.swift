//
//  SearchMediaViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-29.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreData

final class SearchMediaViewModel {
    
    var diffableDataSource: UICollectionViewDiffableDataSource<SearchMediaSection, SearchMediaItem>!
    
    // input
    let context: AppContext
    let searchText = CurrentValueSubject<String, Never>("")
    let searchActionPublisher = PassthroughSubject<Void, Never>()
    
    init(context: AppContext) {
        self.context = context
    }
    
}

extension SearchMediaViewModel {
    
    enum SearchMediaSection: Int {
        case main
        case loader
    }

    enum SearchMediaItem {
        case photo(tweetObjectID: NSManagedObjectID)
        case bottomLoader
    }
    
}

extension SearchMediaViewModel.SearchMediaItem: Equatable {
    static func == (lhs: SearchMediaViewModel.SearchMediaItem, rhs: SearchMediaViewModel.SearchMediaItem) -> Bool {
        switch (lhs, rhs) {
        case (.photo(let objectIDLeft), .photo(let objectIDRight)):
            return objectIDLeft == objectIDRight
        case (.bottomLoader, bottomLoader):
            return true
        default:
            return false
        }
    }
}

extension SearchMediaViewModel.SearchMediaItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .photo(let objectID):
            hasher.combine(objectID)
        case .bottomLoader:
            hasher.combine(String(describing: SearchMediaViewModel.SearchMediaItem.bottomLoader.self))
        }
    }
}

extension SearchMediaViewModel {
    func setupDiffableDataSource(collectionView: UICollectionView) {
        diffableDataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            switch item {
            case .photo(let objectID):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: SearchMediaPhotoCollectionViewCell.self), for: indexPath) as! SearchMediaPhotoCollectionViewCell
                cell.backgroundColor = .systemGray
                return cell
            case .bottomLoader:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ActivityIndicatorCollectionViewCell.self), for: indexPath) as! ActivityIndicatorCollectionViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            }
        }
    }
}
