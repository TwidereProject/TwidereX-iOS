//
//  DataSourceProvider+UserViewTableViewCellDelegate.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-16.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereUI

extension UserTableViewCellDelegate where Self: DataSourceProvider {
    func userTableViewCell(
        _ cell: UserTableViewCell,
        menuActionDidPressed action: UserView.MenuAction,
        menuButton button: UIButton
    ) {
        switch action {
        case .signOut:
            Task {
                let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
                guard let item = await item(from: source) else {
                    assertionFailure()
                    return
                }
                guard case let .user(user) = item else {
                    assertionFailure("only works for status data provider")
                    return
                }
                try await DataSourceFacade.responseToUserSignOut(
                    provider: self,
                    user: user
                )
            }
        }
    }
}
