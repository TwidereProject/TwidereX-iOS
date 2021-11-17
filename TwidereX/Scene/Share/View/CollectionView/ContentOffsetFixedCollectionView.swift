//
//  ContentOffsetFixedCollectionView.swift
//  ContentOffsetFixedCollectionView
//
//  Created by Cirno MainasuK on 2021-8-11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

final class ContentOffsetFixedCollectionView: UICollectionView {
    
    override func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        let _firstVisibleCellIndexPathBefore = indexPathsForVisibleItems.sorted().first
        let _firstVisibleCellBefore = _firstVisibleCellIndexPathBefore.flatMap { cellForItem(at: $0) }
        let _contentOffsetBefore: CGFloat? = {
            guard let firstVisibleCellIndexPathBefore = _firstVisibleCellIndexPathBefore else { return nil }
            guard let layoutAttributes = layoutAttributesForItem(at: firstVisibleCellIndexPathBefore) else { return nil }
            return layoutAttributes.frame.origin.y - bounds.origin.y
        }()
        
        super.performBatchUpdates(updates) { [weak self] isCompletion in
            completion?(isCompletion)
            
            guard let self = self else { return }
            guard let firstVisibleCellBefore = _firstVisibleCellBefore else { return }
            guard let contentOffsetBefore = _contentOffsetBefore else { return }
            guard let newIndexPathForOldFirstVisibleCell = self.indexPath(for: firstVisibleCellBefore) else { return }
            guard let layoutAttributes = self.layoutAttributesForItem(at: newIndexPathForOldFirstVisibleCell) else { return }
            let contentOffsetAfter = layoutAttributes.frame.origin.y - self.bounds.origin.y
            
            let offset = contentOffsetAfter - contentOffsetBefore
            var newContentOffset = self.contentOffset
            newContentOffset.y += offset
            self.contentOffset = newContentOffset
        }
    }
}
