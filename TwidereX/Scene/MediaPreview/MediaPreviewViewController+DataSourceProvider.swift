//
//  MediaPreviewViewController+DataSourceProvider.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-13.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreDataStack
import TwidereCore

// MARK: - DataSourceProvider
extension MediaPreviewViewController: DataSourceProvider {

    @MainActor
    func item(from source: DataSourceItem.Source) async -> DataSourceItem? {
        guard let status = viewModel.status else { return nil }
        return .status(status.asRecord)
    }
    
}
