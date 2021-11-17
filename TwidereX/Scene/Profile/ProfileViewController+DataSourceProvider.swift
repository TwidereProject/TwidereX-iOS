//
//  ProfileViewController+DataSourceProvider.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

// MARK: - DataSourceProvider
extension ProfileViewController: DataSourceProvider {

    func item(from source: DataSourceItem.Source) async -> DataSourceItem? {
        guard let user = viewModel.user else { return nil }
        let record = UserRecord(object: user)
        return DataSourceItem.user(record)
    }
    
    
}
