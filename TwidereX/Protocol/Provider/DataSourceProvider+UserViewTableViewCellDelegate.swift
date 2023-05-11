//
//  DataSourceProvider+UserViewTableViewCellDelegate.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-16.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import CoreData
import CoreDataStack
import SwiftMessages

// MARK: - avatar button
extension UserViewTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        viewModel: UserView.ViewModel,
        userAvatarButtonDidPressed user: UserRecord
    ) {
        Task {
            await DataSourceFacade.coordinateToProfileScene(
                provider: self,
                user: user
            )
        }   // end Task
    }
}


// MARK: - menu button
extension UserViewTableViewCellDelegate where Self: DataSourceProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        viewModel: UserView.ViewModel,
        menuActionDidPressed action: UserView.ViewModel.MenuAction
    ) {
        switch action {
        case .openInNewWindowForAccount:
            guard let userRecord = viewModel.user?.asRecord else { return }
            guard let requestingScene = self.view.window?.windowScene else { return }
            Task { @MainActor in
                let _record: ManagedObjectRecord<AuthenticationIndex>? = await context.managedObjectContext.perform {
                    guard let user = userRecord.object(in: self.context.managedObjectContext) else { return nil }
                    return user.authenticationIndex?.asRecrod
                }
                guard let record = _record else { return }
                try SceneDelegate.openSceneSessionForAccount(record, fromRequestingScene: requestingScene)
            }   // end Task
        case .signOut:
            Task {
                guard let user = viewModel.user?.asRecord else {
                    assertionFailure()
                    return
                }
                try await DataSourceFacade.responseToUserSignOut(
                    dependency: self,
                    user: user
                )
            }   // end Task
            
        case .removeListMember:
            Task { @MainActor in
                guard !viewModel.isListMemberCandidate else { return }
                guard let authenticationContext = viewModel.authContext?.authenticationContext else { return }
                guard let listMembershipViewModel = viewModel.listMembershipViewModel else { return }
                guard let user = viewModel.user?.asRecord else { return }
                do {
                    try await listMembershipViewModel.remove(user: user, authenticationContext: authenticationContext)
                    
                    var config = SwiftMessages.defaultConfig
                    config.duration = .seconds(seconds: 3)
                    config.interactiveHide = true
                    let bannerView = NotificationBannerView()
                    bannerView.configure(style: .success)
                    bannerView.titleLabel.text = L10n.Common.Alerts.ListMemberRemoved.title
                    bannerView.messageLabel.isHidden = true
                    SwiftMessages.show(config: config, view: bannerView)
                } catch {
                    var config = SwiftMessages.defaultConfig
                    config.duration = .seconds(seconds: 3)
                    config.interactiveHide = true
                    let bannerView = NotificationBannerView()
                    bannerView.configure(style: .warning)
                    bannerView.titleLabel.text = L10n.Common.Alerts.FailedToRemoveListMember.title
                    bannerView.messageLabel.text = error.localizedDescription
                    SwiftMessages.show(config: config, view: bannerView)
                }
            }   // end Task
        }   // end switch
    }    
}

// MARK: - friendship button
extension UserViewTableViewCellDelegate where Self: DataSourceProvider {

//    func tableViewCell(
//        _ cell: UITableViewCell,
//        userView: UserView,
//        friendshipButtonDidPressed button: UIButton
//    ) {
//        assertionFailure("TODO")
//    }

}

// MARK: - membership
extension UserViewTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        viewModel: UserView.ViewModel,
        listMembershipButtonDidPressed user: UserRecord
    ) {
        guard !viewModel.isListMemberCandidate else {
            return
        }

        Task { @MainActor in
            guard !viewModel.isListMemberCandidate else { return }
            guard let authenticationContext = viewModel.authContext?.authenticationContext else { return }
            guard let listMembershipViewModel = viewModel.listMembershipViewModel else { return }
            guard let user = viewModel.user?.asRecord else { return }
            do {
                if viewModel.isListMember {
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
                bannerView.titleLabel.text = viewModel.isListMember ? L10n.Common.Alerts.FailedToRemoveListMember.title : L10n.Common.Alerts.FailedToAddListMember.title
                bannerView.messageLabel.text = error.localizedDescription
                SwiftMessages.show(config: config, view: bannerView)
            }
        }   // end Task
    }
}

// MARK: - follow request
extension UserViewTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        viewModel: UserView.ViewModel,
        followReqeustButtonDidPressed user: UserRecord,
        accept: Bool
    ) {
        Task {
            guard let notification = viewModel.notification?.asRecord else {
                assertionFailure()
                return
            }
            
            try await DataSourceFacade.responseToUserFollowRequestAction(
                dependency: self,
                notification: notification,
                query: accept ? .accept : .reject,
                authenticationContext: self.authContext.authenticationContext
            )
        }   // end Task
    }

//    func tableViewCell(
//        _ cell: UITableViewCell,
//        userView: UserView,
//        acceptFollowReqeustButtonDidPressed button: UIButton
//    ) {
//        Task {
//            let authenticationContext = self.authContext.authenticationContext
//
//            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
//            guard let item = await item(from: source) else {
//                assertionFailure()
//                return
//            }
//            guard case let .notification(notification) = item else {
//                assertionFailure("only works for notification data")
//                return
//            }
//
//            try await DataSourceFacade.responseToUserFollowRequestAction(
//                dependency: self,
//                notification: notification,
//                query: .accept,
//                authenticationContext: authenticationContext
//            )
//        }   // end Task
//    }
//
//    func tableViewCell(
//        _ cell: UITableViewCell,
//        userView: UserView,
//        rejectFollowReqeustButtonDidPressed button: UIButton
//    ) {
//        Task {
//            let authenticationContext = self.authContext.authenticationContext
//
//            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
//            guard let item = await item(from: source) else {
//                assertionFailure()
//                return
//            }
//            guard case let .notification(notification) = item else {
//                assertionFailure("only works for notification data")
//                return
//            }
//
//            try await DataSourceFacade.responseToUserFollowRequestAction(
//                dependency: self,
//                notification: notification,
//                query: .reject,
//                authenticationContext: authenticationContext
//            )
//        }   // end Task
//    }

}
