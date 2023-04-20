//
//  DataSourceProvider+Friendship.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import CoreData
import CoreDataStack
import TwidereCore
import TwitterSDK
import MastodonSDK
import SwiftMessages

extension DataSourceFacade {
    static func responseToFriendshipButtonAction(
        provider: DataSourceProvider,
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async {
        let impactFeedbackGenerator = await UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = await UINotificationFeedbackGenerator()
        
        await impactFeedbackGenerator.impactOccurred()
        do {
            try await provider.context.apiService.follow(
                user: user,
                authenticationContext: authenticationContext
            )
            await notificationFeedbackGenerator.notificationOccurred(.success)
        } catch let error as Twitter.API.Error.ResponseError where error.httpResponseStatus == .forbidden {
            await notificationFeedbackGenerator.notificationOccurred(.error)
            await presentForbiddenBanner(
                error: error,
                dependency: provider
            )
        } catch {
            await notificationFeedbackGenerator.notificationOccurred(.error)
        }
    }
}

extension DataSourceFacade {
    
    enum FollowRequestQuery {
        case accept
        case reject
    }
    
    static func responseToUserFollowRequestAction(
        dependency: NeedsDependency,
        notification: NotificationRecord,
        query: FollowRequestQuery,
        authenticationContext: AuthenticationContext
    ) async throws {
        let impactFeedbackGenerator = await UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = await UINotificationFeedbackGenerator()

        await impactFeedbackGenerator.impactOccurred()
        
        do {
            switch (notification, authenticationContext) {
            case (.twitter, .twitter):
                assertionFailure("Twitter notification has no entry for follow request")
                return
            case (.mastodon(let notification), .mastodon(let authenticationContext)):
                try await responseToUserFollowRequestAction(
                    dependency: dependency,
                    notification: notification,
                    query: {
                        switch query {
                        case .accept:       return .accept
                        case .reject:       return .reject
                        }
                    }(),
                    authenticationContext: authenticationContext
                )
            default:
                assertionFailure()
                return
            }   // end switch
            
            await notificationFeedbackGenerator.notificationOccurred(.success)
        } catch {
            await notificationFeedbackGenerator.notificationOccurred(.error)
        }
    }   // end func
    
    struct MastodonFollwRequestContext {
        let user: ManagedObjectRecord<MastodonUser>
        let isBusy: Bool
    }
    
    static func responseToUserFollowRequestAction(
        dependency: NeedsDependency,
        notification: ManagedObjectRecord<MastodonNotification>,
        query: Mastodon.API.Account.FollowReqeustQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws {
        let managedObjectContext = dependency.context.managedObjectContext
        let _mastodonFollwRequestContext: MastodonFollwRequestContext? = await managedObjectContext.perform {
            guard let notification = notification.object(in: managedObjectContext) else { return nil }
            return .init(
                user: .init(objectID: notification.account.objectID),
                isBusy: notification.isFollowRequestBusy
            )
        }

        guard let mastodonFollwRequestContext = _mastodonFollwRequestContext else {
            assertionFailure()
            throw AppError.implicit(.badRequest)
        }

        guard !mastodonFollwRequestContext.isBusy else {
            return
        }

        // update transient on main context
        try? await managedObjectContext.performChanges {
            guard let notification = notification.object(in: managedObjectContext) else { return }
            notification.update(isFollowRequestBusy: true)
        }

        do {
            _ = try await dependency.context.apiService.followRequest(
                user: mastodonFollwRequestContext.user,
                query: query,
                authenticationContext: authenticationContext
            )
        } catch {
            // update transient on main context
            try? await managedObjectContext.performChanges {
                guard let notification = notification.object(in: managedObjectContext) else { return }
                notification.update(isFollowRequestBusy: false)
            }

            if let error = error as? Mastodon.API.Error {
                switch error.httpResponseStatus {
                case .notFound:
                    let backgroundManagedObjectContext = dependency.context.backgroundManagedObjectContext
                    try await backgroundManagedObjectContext.performChanges {
                        guard let notification = notification.object(in: backgroundManagedObjectContext) else { return }
                        for feed in notification.feeds {
                            backgroundManagedObjectContext.delete(feed)
                        }
                        backgroundManagedObjectContext.delete(notification)
                    }
                default:
                    let alertController = await UIAlertController.standardAlert(of: error)
                    await dependency.coordinator.present(
                        scene: .alertController(alertController: alertController),
                        from: nil,
                        transition: .alertController(animated: true, completion: nil)
                    )
                }   // end switch
            }
            
            return
        }

        // update transient on main context
        try? await managedObjectContext.performChanges {
            guard let notification = notification.object(in: managedObjectContext) else { return }
            notification.update(isFollowRequestBusy: false)
        }

        let backgroundManagedObjectContext = dependency.context.backgroundManagedObjectContext
        try await backgroundManagedObjectContext.performChanges {
            guard let notification = notification.object(in: backgroundManagedObjectContext) else { return }
            for feed in notification.feeds {
                backgroundManagedObjectContext.delete(feed)
            }
            backgroundManagedObjectContext.delete(notification)
        }

        await presentFollowRequestResponse(query: query)
    }   // end func
    
    @MainActor
    private static func presentFollowRequestResponse(query: Mastodon.API.Account.FollowReqeustQuery) async {
        var config = SwiftMessages.defaultConfig
        config.duration = .seconds(seconds: 3)
        config.interactiveHide = true

        let bannerView = NotificationBannerView()
        bannerView.configure(style: .success)
        bannerView.titleLabel.text = {
            switch query {
            case .accept:       return L10n.Common.Notification.FollowRequestResponse.followRequestApproved
            case .reject:       return L10n.Common.Notification.FollowRequestResponse.followRequestDenied
            }
        }()
        bannerView.messageLabel.isHidden = true
        
        SwiftMessages.show(config: config, view: bannerView)
    }
    
}
