//
//  DataSourceProvider+UserViewTableViewCellDelegate.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-16.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereUI

extension UserViewTableViewCellDelegate where Self: DataSourceProvider {
    
    func tableViewCell(
        _ cell: UITableViewCell,
        userView: UserView,
        menuActionDidPressed action: UserView.MenuAction,
        menuButton button: UIButton
    ) {
        switch action {
        case .signOut:
            // TODO: move to view controller
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
            }   // end Task
        case .remove:
            assertionFailure("Override in view controller")
        }   // end swtich
    }

    func tableViewCell(
        _ cell: UITableViewCell,
        userView: UserView,
        friendshipButtonDidPressed button: UIButton
    ) {
        assertionFailure("TODO")
    }

    func tableViewCell(
        _ cell: UITableViewCell,
        userView: UserView,
        membershipButtonDidPressed button: UIButton
    ) {
        guard !userView.viewModel.isListMemberCandidate else {
            return
        }
        
        Task {
            guard let authenticationContext = context.authenticationService.activeAuthenticationContext else {
                return
            }
            
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .user(user) = item else {
                assertionFailure("only works for status data provider")
                return
            }
            
            guard let listMembershipViewModel = await userView.viewModel.listMembershipViewModel else {
                assertionFailure()
                return
            }
            
            if await userView.viewModel.isListMember {
                try await listMembershipViewModel.remove(user: user, authenticationContext: authenticationContext)
            } else {
                try await listMembershipViewModel.add(user: user, authenticationContext: authenticationContext)
            }
            
        }   // end Task
    }

}
