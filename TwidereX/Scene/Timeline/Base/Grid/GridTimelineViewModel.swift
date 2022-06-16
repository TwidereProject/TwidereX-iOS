//
//  GridTimelineViewModel+ViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-13.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit

class GridTimelineViewModel: TimelineViewModel {
    
    var diffableDataSource: UICollectionViewDiffableDataSource<StatusSection, StatusItem>?
    
    @MainActor
    override func updateDataSource(
        snapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>,
        animatingDifferences: Bool
    ) {
        diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    @MainActor
    override func updateSnapshotUsingReloadData(
        snapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>
    ) {
        diffableDataSource?.applySnapshotUsingReloadData(snapshot)
    }
    
}
