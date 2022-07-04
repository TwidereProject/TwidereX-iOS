//
//  DataSourceProvider+UserViewTableViewCellDelegate.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-16.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereUI
import SwiftMessages

// MARK: - menu button
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
                    assertionFailure("only works for user data")
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
    
}

// MARK: - friendship button
extension UserViewTableViewCellDelegate where Self: DataSourceProvider {

    func tableViewCell(
        _ cell: UITableViewCell,
        userView: UserView,
        friendshipButtonDidPressed button: UIButton
    ) {
        assertionFailure("TODO")
    }

}

// MARK: - membership
extension UserViewTableViewCellDelegate where Self: DataSourceProvider {

    func tableViewCell(
        _ cell: UITableViewCell,
        userView: UserView,
        membershipButtonDidPressed button: UIButton
    ) {
        guard !userView.viewModel.isListMemberCandidate else {
            return
        }
        
        Task { @MainActor in
            guard let authenticationContext = context.authenticationService.activeAuthenticationContext else {
                return
            }
            
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .user(user) = item else {
                assertionFailure("only works for user data")
                return
            }
            
            guard let listMembershipViewModel = userView.viewModel.listMembershipViewModel else {
                assertionFailure()
                return
            }
            
            do {
                if userView.viewModel.isListMember {
                    try await listMembershipViewModel.remove(user: user, authenticationContext: authenticationContext)
                } else {
                    try await listMembershipViewModel.add(user: user, authenticationContext: authenticationContext)
                }
            } catch {
                var config = SwiftMessages.defaultConfig
                config.duration = .seconds(seconds: 3)
                config.interactiveHide = true
                let bannerView = NotificationBannerView()
                bannerView.configure(style: .warning)
                bannerView.titleLabel.text = L10n.Common.Alerts.FailedToAddListMember.title
                bannerView.messageLabel.text = error.localizedDescription
                SwiftMessages.show(config: config, view: bannerView)
            }
        }   // end Task
    }

}

// MARK: - follow request
extension UserViewTableViewCellDelegate where Self: DataSourceProvider {

    func tableViewCell(
        _ cell: UITableViewCell,
        userView: UserView,
        acceptFollowReqeustButtonDidPressed button: UIButton
    ) {
        Task {
            guard let authenticationContext = context.authenticationService.activeAuthenticationContext else {
                return
            }
            
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .notification(notification) = item else {
                assertionFailure("only works for notification data")
                return
            }
            
            try await DataSourceFacade.responseToUserFollowRequestAction(
                dependency: self,
                notification: notification,
                query: .accept,
                authenticationContext: authenticationContext
            )
        }   // end Task
    }
    
    func tableViewCell(
        _ cell: UITableViewCell,
        userView: UserView,
        rejectFollowReqeustButtonDidPressed button: UIButton
    ) {
        Task {
            guard let authenticationContext = context.authenticationService.activeAuthenticationContext else {
                return
            }
            
            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
            guard let item = await item(from: source) else {
                assertionFailure()
                return
            }
            guard case let .notification(notification) = item else {
                assertionFailure("only works for notification data")
                return
            }
            
            try await DataSourceFacade.responseToUserFollowRequestAction(
                dependency: self,
                notification: notification,
                query: .reject,
                authenticationContext: authenticationContext
            )
        }   // end Task
    }

}
