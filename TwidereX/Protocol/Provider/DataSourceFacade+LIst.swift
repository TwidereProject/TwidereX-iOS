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
    
    static func createMenuForList(
        dependency: NeedsDependency,
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
        ) { [weak dependency] action in
            
        }
        children.append(membersAction)
        
        let subscribersAction = await UIAction(
            title: L10n.Scene.ListsDetails.Tabs.subscriber,
            image: UIImage(systemName: "person.crop.rectangle.stack"),
            identifier: nil,
            discoverabilityTitle: nil,
            attributes: [],
            state: .off
        ) { [weak dependency] action in
            
        }
        children.append(subscribersAction)
        
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
        }
        
        let title: String = await managedObjectContext.perform {
            guard let list = list.object(in: managedObjectContext) else { return "" }
            switch list.owner {
            case .twitter(let user):        return "\(user.name)\n@\(user.username)"
            case .mastodon(let user):       return "\(user.name)\n@\(user.acctWithDomain)"
            }
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
                try await DataSourceFacade.responseListFollowAction(
                    dependency: dependency,
                    list: list,
                    relationship: relationship,
                    authenticationContext: authenticationContext
                )
            }   // end Task
        }
        
        return action
    }
    
    @MainActor
    private static func responseListFollowAction(
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
            bannerView.titleLabel.text = L10n.Common.Alerts.FollowingSuccess.title
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
            bannerView.titleLabel.text = L10n.Common.Alerts.FailedToFollowing.title
            bannerView.messageLabel.text = L10n.Common.Alerts.FailedToFollowing.message
            SwiftMessages.show(config: config, view: bannerView)
        }
    }
    
}
