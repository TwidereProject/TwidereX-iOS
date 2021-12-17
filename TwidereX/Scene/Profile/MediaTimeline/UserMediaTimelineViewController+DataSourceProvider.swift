//
//  UserMediaTimelineViewController+DataSourceProvider.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

// MARK: - DataSourceProvider
extension UserMediaTimelineViewController: DataSourceProvider {
    func item(from source: DataSourceItem.Source) async -> DataSourceItem? {
        var _indexPath = source.indexPath
        if _indexPath == nil, let cell = source.collectionViewCell {
            _indexPath = await self.indexPath(for: cell)
        }
        guard let indexPath = _indexPath else { return nil }
        
        guard let item = viewModel.diffableDataSource?.itemIdentifier(for: indexPath) else {
            return nil
        }
        
        switch item {
        case .status(let record):
            return .status(record)
        default:
            return nil
        }
    }
    
    @MainActor
    private func indexPath(for cell: UICollectionViewCell) async -> IndexPath? {
        return collectionView.indexPath(for: cell)
    }
}
