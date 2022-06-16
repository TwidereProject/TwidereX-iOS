//
//  TimelineViewModelDriver.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-14.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit

class TimelineViewModelDriver {

    @MainActor
    func updateDataSource(
        snapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>,
        animatingDifferences: Bool
    ) {
        assertionFailure("should not call the base implementation")
    }
    
    @MainActor
    func updateSnapshotUsingReloadData(
        snapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>
    ) {
        assertionFailure("should not call the base implementation")
    }
    
}
