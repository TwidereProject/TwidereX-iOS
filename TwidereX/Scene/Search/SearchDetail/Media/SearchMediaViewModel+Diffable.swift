//
//  SearchMediaViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData

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
