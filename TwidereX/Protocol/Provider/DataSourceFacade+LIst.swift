//
//  DataSourceFacade+LIst.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-9.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import CoreDataStack
import TwidereAsset
import TwidereLocalization
import TwidereCore
import TwitterSDK
import SwiftMessages

extension DataSourceFacade {
    
    static func coordinateToListMemberScene(
        dependency: NeedsDependency & UIViewController,
        list: ListRecord
    ) async {
        let listUserViewModel = ListUserViewModel(
            context: dependency.context,
            kind: .members(list: list)
        )
        await dependency.coordinator.present(
            scene: .listUser(viewModel: listUserViewModel),
            from: dependency,
            transition: .show
        )
    }
    
    static func coordinateToListSubscriberScene(
        dependency: NeedsDependency & UIViewController,
        list: ListRecord
    ) async {
        let listUserViewModel = ListUserViewModel(
            context: dependency.context,
            kind: .subscribers(list: list)
        )
        await dependency.coordinator.present(
            scene: .listUser(viewModel: listUserViewModel),
            from: dependency,
            transition: .show
        )
    }
    
}

extension DataSourceFacade {
    
    static func createMenuForList(
        dependency: NeedsDependency & UIViewController,
        list: ListRecord,
        authenticationContext: AuthenticationContext
    ) async throws -> UIMenu {
        let managedObjectContext = dependency.context.managedObjectContext
        var children: [UIMenuElement] = []

        let membersAction = await UIAction(
            title: L10n.Scene.ListsDetails.Tabs.members,
            image: UIImage(systemName: "person.crop.rectangle.stack"),
            identifier: nil,
            discoverabilityTitle: nil,
            attributes: [],
            state: .off
        ) { [weak dependency] _ in
            guard let dependency = dependency else { return }
            Task {
                await coordinateToListMemberScene(
                    dependency: dependency,
                    list: list
                )
            }   // end Task
        }
        children.append(membersAction)
        
        let _subscribersAction: UIAction? = await {
            switch list {
            case .twitter:  break
            case .mastodon: return nil
            }
            return await UIAction(
                title: L10n.Scene.ListsDetails.Tabs.subscriber,
                image: UIImage(systemName: "person.2"),
                identifier: nil,
                discoverabilityTitle: nil,
                attributes: [],
                state: .off
            ) { [weak dependency] _ in
                guard let dependency = dependency else { return }
                Task {
                    await coordinateToListSubscriberScene(
                        dependency: dependency,
                        list: list
                    )
                }   // end Task
            }
        }()
        if let action = _subscribersAction {
            children.append(action)
        }
        
        let isMyList: Bool = await managedObjectContext.perform {
            guard let list = list.object(in: managedObjectContext) else { return false }
            return list.owner.userIdentifer == authenticationContext.userIdentifier
        }
        if !isMyList {
            let followAction: UIMenuElement = await UIDeferredMenuElement.uncached { [weak dependency] elementsProvider in
                guard let dependency = dependency else {
                    elementsProvider([])
                    return
                }
                
                // the elmentsProvider needs dispath on the mainQueue
                Task { @MainActor in
                    do {
                        let relationship = try await dependency.context.apiService.followRelationship(
                            list: list,
                            authenticationContext: authenticationContext
                        )
                        let _action = try await createListFollowAction(
                            dependency: dependency,
                            list: list,
                            relationship: relationship,
                            authenticationContext: authenticationContext
                        )
                        let elements = [_action].compactMap { $0 }
                        elementsProvider(elements)
                    } catch {
                        elementsProvider([])
                    }
                }   // end Task
            }
            children.append(followAction)
        } else {
            let editAction = await UIAction(
                title: L10n.Common.Controls.Actions.edit,
                subtitle: nil,
                image: UIImage(systemName: "pencil"),
                identifier: nil,
                discoverabilityTitle: nil,
                attributes: [],
                state: .off
            ) { [weak dependency] _ in
                guard let dependency = dependency else { return }
                Task {
                    try await responseToListEditAction(
                        dependency: dependency,
                        list: list,
                        authenticationContext: authenticationContext
                    )
                }   // end Task
            }
            children.append(editAction)
            
            let deleteAction = await UIAction(
                title: L10n.Common.Controls.Actions.delete,
                image: UIImage(systemName: "minus.circle"),
                identifier: nil,
                discoverabilityTitle: nil,
                attributes: [.destructive],
                state: .off
            ) { [weak dependency] _ in
                guard let dependency = dependency else { return }
                Task {
                    try await responseToListDeleteAction(
                        dependency: dependency,
                        list: list,
                        authenticationContext: authenticationContext
                    )
                }   // end Task
            }
            children.append(deleteAction)
        }
        
        let title: String = await managedObjectContext.perform {
            guard isMyList else { return "" }
            guard let list = list.object(in: managedObjectContext) else { return "" }
            switch list.owner {
            case .twitter(let user):        return "\(user.name)\n@\(user.username)"
            case .mastodon(let user):       return "\(user.name)\n@\(user.acctWithDomain)"
            }
        }
        let _ownerAction: UIAction? = await {
            guard !isMyList else { return nil }
            let _name: String? = await managedObjectContext.perform {
                guard let list = list.object(in: managedObjectContext) else { return nil }
                switch list.owner {
                case .twitter(let user):        return user.name
                case .mastodon(let user):       return user.name
                }
            }
            let _username: String? = await managedObjectContext.perform {
                guard let list = list.object(in: managedObjectContext) else { return nil }
                switch list.owner {
                case .twitter(let user):        return "@" + user.username
                case .mastodon(let user):       return "@" + user.acct
                }
            }
            let _owner: UserRecord? = await managedObjectContext.perform {
                guard let list = list.object(in: managedObjectContext) else { return nil }
                return list.owner.asRecord
            }
            guard let name = _name,
                  let username = _username,
                  let owner = _owner
            else { return nil }
            return await UIAction(
                title: name,
                subtitle: username,
                image: UIImage(systemName: "person.crop.circle"),
                identifier: nil,
                discoverabilityTitle: nil,
                attributes: [],
                state: .off
            ) { _ in
                Task { @MainActor [weak dependency] in
                    guard let dependency = dependency else { return }
                    let profileViewModel = LocalProfileViewModel(context: dependency.context, userRecord: owner)
                    dependency.coordinator.present(
                        scene: .profile(viewModel: profileViewModel),
                        from: dependency,
                        transition: .show
                    )
                }   // end Task
            }
        }()
        if let action = _ownerAction {
            children.insert(action, at: 0)
        }
        return await UIMenu(
            title: title,
            options: [],
            children: children
        )
    }
    
}

extension DataSourceFacade {
    
    private static func createListFollowAction(
        dependency: NeedsDependency,
        list: ListRecord,
        relationship: APIService.ListRelationship,
        authenticationContext: AuthenticationContext
    ) async throws -> UIAction? {
        let isFollowing = relationship.isFollowing
        
        let action = await UIAction(
            title: isFollowing ? L10n.Scene.ListsDetails.MenuActions.unfollow : L10n.Scene.ListsDetails.MenuActions.follow,
            image: isFollowing ? UIImage(systemName: "rectangle.stack.badge.minus") : UIImage(systemName: "rectangle.stack.badge.plus"),
            identifier: nil,
            discoverabilityTitle: nil,
            attributes: [],
            state: .off
        ) { [weak dependency] _ in
            guard let dependency = dependency else { return }
            Task {
                try await DataSourceFacade.responseToListFollowAction(
                    dependency: dependency,
                    list: list,
                    relationship: relationship,
                    authenticationContext: authenticationContext
                )
            }   // end Task
        }
        
        return action
    }
    
}
    

extension DataSourceFacade {
    
    @MainActor
    private static func responseToListFollowAction(
        dependency: NeedsDependency,
        list: ListRecord,
        relationship: APIService.ListRelationship,
        authenticationContext: AuthenticationContext
    ) async throws {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        
        do {
            impactFeedbackGenerator.impactOccurred()
            try await dependency.context.apiService.follow(
                list: list,
                relationship: relationship,
                authenticationContext: authenticationContext
            )
            notificationFeedbackGenerator.notificationOccurred(.success)
            
            // success HUD
            var config = SwiftMessages.defaultConfig
            config.duration = .seconds(seconds: 3)
            config.interactiveHide = true
            let bannerView = NotificationBannerView()
            bannerView.configure(style: .success)
            bannerView.titleLabel.text = relationship.isFollowing ? L10n.Common.Alerts.UnfollowingSuccess.title : L10n.Common.Alerts.FollowingSuccess.title
            bannerView.messageLabel.isHidden = true
            SwiftMessages.show(config: config, view: bannerView)
            
        } catch {
            notificationFeedbackGenerator.notificationOccurred(.error)
            
            // warning HUD
            var config = SwiftMessages.defaultConfig
            config.duration = .seconds(seconds: 3)
            config.interactiveHide = true
            let bannerView = NotificationBannerView()
            bannerView.configure(style: .warning)
            bannerView.titleLabel.text = relationship.isFollowing ? L10n.Common.Alerts.FailedToUnfollowing.title : L10n.Common.Alerts.FailedToFollowing.title
            bannerView.messageLabel.text = relationship.isFollowing ? L10n.Common.Alerts.FailedToUnfollowing.message : L10n.Common.Alerts.FailedToFollowing.message
            SwiftMessages.show(config: config, view: bannerView)
        }
    }
    
    @MainActor
    static func responseToListDeleteAction(
        dependency: NeedsDependency & UIViewController,
        list: ListRecord,
        authenticationContext: AuthenticationContext
    ) async throws {
        let title = L10n.Scene.ListsDetails.MenuActions.deleteList
        let message: String = await dependency.context.managedObjectContext.perform {
            guard let object = list.object(in: dependency.context.managedObjectContext) else {
                return L10n.Scene.ListsDetails.deleteListTitle
            }
            return L10n.Scene.ListsDetails.deleteListConfirm(object.name)
        }
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let deleteAction = UIAlertAction(
            title: L10n.Common.Controls.Actions.delete,
            style: .destructive
        ) { [weak dependency] _ in
            guard let dependency = dependency else { return }
            Task {
                let notificationFeedbackGenerator = UINotificationFeedbackGenerator()

                do {
                    try await dependency.context.apiService.deleteList(
                        list: list,
                        authenticationContext: authenticationContext
                    )
                    notificationFeedbackGenerator.notificationOccurred(.success)
                    presentSuccessBanner(title: "List Deleted")   // TODO: i18n
                } catch {
                    notificationFeedbackGenerator.notificationOccurred(.error)
                    presentWarningBanner(
                        title: "Failed to Delete List", // TODO: i18n
                        message: "Please try again",    // TODO: i18n
                        error: error
                    )
                }
            }   // end Task
        }
        alertController.addAction(deleteAction)
        let cancelAction = UIAlertAction.cancel
        alertController.addAction(cancelAction)
        dependency.coordinator.present(
            scene: .alertController(alertController: alertController),
            from: dependency,
            transition: .alertController(animated: true, completion: nil)
        )
    }
    
    @MainActor
    static func responseToListEditAction(
        dependency: NeedsDependency & UIViewController,
        list: ListRecord,
        authenticationContext: AuthenticationContext
    ) async throws {
        let editListViewModel = EditListViewModel(
            context: dependency.context,
            platform: {
                switch list {
                case .twitter:      return .twitter
                case .mastodon:     return .mastodon
                }
            }(),
            kind: .edit(list: list)
        )
        dependency.coordinator.present(
            scene: .editList(viewModel: editListViewModel),
            from: dependency,
            transition: .modal(animated: true, completion: nil)
        )
    }
    
}
