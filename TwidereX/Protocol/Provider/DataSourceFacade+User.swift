//
//  DataSourceProvider+User.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-21.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import CoreDataStack
import TwidereAsset
import TwidereLocalization

extension DataSourceFacade {
    static func createMenuForUser(
        provider: DataSourceProvider,
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async throws -> UIMenu {
        var children: [UIMenuElement] = []
        
        let relationshipOptionSet = try await DataSourceFacade.relationshipOptionSet(
            provider: provider,
            record: user,
            authenticationContext: authenticationContext
        )
        
        let isMyself = relationshipOptionSet.contains(.isMyself)
        
        if !isMyself {
            // mute
            let isMuting = relationshipOptionSet.contains(.muting)
            let muteAction = await createMenuMuteActionForUser(
                provider: provider,
                record: user,
                authenticationContext: authenticationContext,
                isMuting: isMuting
            )
            children.append(muteAction)

            // block
            let isBlocking = relationshipOptionSet.contains(.blocking)
            let blockAction = await createMenuBlockActionForUser(
                provider: provider,
                record: user,
                authenticationContext: authenticationContext,
                isBlocking: isBlocking
            )
            children.append(blockAction)
            
            // report
            let reportAction = await createMenuReportActionForUser(
                provider: provider,
                record: user,
                authenticationContext: authenticationContext
            )
            children.append(reportAction)
        }
        
        return await UIMenu(title: "", options: [], children: children)
    }
}
 
extension DataSourceFacade {
    static func relationshipOptionSet(
        provider: DataSourceProvider,
        record: UserRecord,
        authenticationContext: AuthenticationContext
    ) async throws -> RelationshipOptionSet {
        let managedObjectContext = provider.context.managedObjectContext
        let relationshipOptionSet: RelationshipOptionSet = try await managedObjectContext.perform {
            guard let user = record.object(in: managedObjectContext),
                  let me = authenticationContext.user(in: managedObjectContext)
            else { throw AppError.implicit(.badRequest) }
            return RelationshipViewModel.optionSet(user: user, me: me)
        }
        return relationshipOptionSet
    }
}

extension DataSourceFacade {
    
    // mute // unmute
    private static func createMenuMuteActionForUser(
        provider: DataSourceProvider,
        record: UserRecord,
        authenticationContext: AuthenticationContext,
        isMuting: Bool
    ) async -> UIAction {
        let title = isMuting ? L10n.Common.Controls.Friendship.Actions.unmute : L10n.Common.Controls.Friendship.Actions.mute
        let image = isMuting ? UIImage(systemName: "speaker.wave.2") : UIImage(systemName: "speaker.slash")
        let muteAction = await UIAction(title: title, image: image, attributes: [], state: .off) { [weak provider] _ in
            guard let provider = provider else { return }
            Task {
                await DataSourceFacade.presentUserMuteAlert(
                    provider: provider,
                    user: record,
                    authenticationContext: authenticationContext
                )
            }
        }
        return muteAction
    }
    
    // block / unblock
    private static func createMenuBlockActionForUser(
        provider: DataSourceProvider,
        record: UserRecord,
        authenticationContext: AuthenticationContext,
        isBlocking: Bool
    ) async -> UIAction {
        let title = isBlocking ? L10n.Common.Controls.Friendship.Actions.unblock : L10n.Common.Controls.Friendship.Actions.block
        let image = isBlocking ? UIImage(systemName: "circle") : UIImage(systemName: "nosign")
        let blockAction = await UIAction(title: title, image: image, attributes: [], state: .off) { [weak provider] _ in
            guard let provider = provider else { return }
            Task {
                await DataSourceFacade.presentUserBlockAlert(
                    provider: provider,
                    user: record,
                    authenticationContext: authenticationContext
                )
            }
        }
        return blockAction
    }

    private static func createMenuReportActionForUser(
        provider: DataSourceProvider,
        record: UserRecord,
        authenticationContext: AuthenticationContext
    ) async -> UIMenuElement {
        let reportAction = await UIAction(
            title: L10n.Common.Controls.Friendship.Actions.report,
            image: UIImage(systemName: "flag"),
            identifier: nil,
            discoverabilityTitle: nil,
            attributes: .destructive,
            state: .off
        ) { [weak provider] _ in
            guard let provider = provider else { return }
            Task {
                await DataSourceFacade.presentUserReportAlert(
                    provider: provider,
                    user: record,
                    performBlock: false,
                    authenticationContext: authenticationContext
                )
            }
        }
        
        switch record {
        case .twitter:
            let reportAndBlockAction = await UIAction(
                title: L10n.Common.Controls.Friendship.Actions.reportAndBlock,
                image: UIImage(systemName: "flag.badge.ellipsis"),
                identifier: nil,
                discoverabilityTitle: nil,
                attributes: .destructive,
                state: .off
            ) { [weak provider] _ in
                guard let provider = provider else { return }
                Task {
                    await DataSourceFacade.presentUserReportAlert(
                        provider: provider,
                        user: record,
                        performBlock: true,
                        authenticationContext: authenticationContext
                    )
                }
            }
            return await UIMenu(
                title: L10n.Common.Controls.Friendship.Actions.report,
                image: UIImage(systemName: "flag"),
                identifier: nil,
                options: [],
                children: [
                    reportAction,
                    reportAndBlockAction
                ]
            )
        case .mastodon:
            return reportAction
        }
    }

}

extension DataSourceFacade {
    @MainActor
    static func responseToUserSignOut(
        provider: DataSourceProvider,
        user: UserRecord
    ) async throws  {
        let alertController = UIAlertController(
            title: L10n.Common.Alerts.SignOutUserConfirm.title,
            message: L10n.Common.Alerts.SignOutUserConfirm.message,
            preferredStyle: .alert
        )
        let signOutAction = UIAlertAction(
            title: L10n.Common.Controls.Actions.signOut,
            style: .destructive
        ) { [weak provider] _ in
            guard let provider = provider else { return }
            Task {
                var isSignOut = false
                
                let managedObjectContext = provider.context.backgroundManagedObjectContext
                try await managedObjectContext.performChanges {
                    guard let object = user.object(in: managedObjectContext) else { return }
                    switch object {
                    case .twitter(let user):
                        guard let authentication = user.twitterAuthentication else {
                            return
                        }
                        managedObjectContext.delete(authentication.authenticationIndex)
                        managedObjectContext.delete(authentication)
                        isSignOut = true
                    case .mastodon(let user):
                        guard let authentication = user.mastodonAuthentication else {
                            return
                        }
                        managedObjectContext.delete(authentication.authenticationIndex)
                        managedObjectContext.delete(authentication)
                        isSignOut = true
                    }
                }
                
                guard isSignOut else { return }
                provider.coordinator.setup()
                provider.coordinator.setupWelcomeIfNeeds()
            }   // end Task
        }
        alertController.addAction(signOutAction)
        let cancelAction = UIAlertAction.cancel
        alertController.addAction(cancelAction)
        provider.coordinator.present(
            scene: .alertController(alertController: alertController),
            from: provider,
            transition: .alertController(animated: true, completion: nil)
        )
    }
}
