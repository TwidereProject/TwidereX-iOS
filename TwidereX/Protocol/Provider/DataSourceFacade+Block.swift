//
//  DataSourceFacade+Block.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-21.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

extension DataSourceFacade {
    @MainActor
    static func presentUserBlockAlert(
        provider: DataSourceProvider,
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()

        do {
            let alertController = try await DataSourceFacade.createUserBlockAlert(
                provider: provider,
                user: user,
                authenticationContext: authenticationContext
            )
            impactFeedbackGenerator.impactOccurred()
            provider.coordinator.present(
                scene: .alertController(alertController: alertController),
                from: provider,
                transition: .alertController(animated: true, completion: nil)
            )
        } catch {
            notificationFeedbackGenerator.notificationOccurred(.error)
        }
    }
}

extension DataSourceFacade {
    
    private struct BlockAlertContext {
        let isBlocking: Bool
        let name: String
    }
    
    @MainActor
    static func createUserBlockAlert(
        provider: DataSourceProvider,
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async throws -> UIAlertController {
        let managedObjectContext = provider.context.managedObjectContext
        let blockAlertContext: BlockAlertContext = try await managedObjectContext.perform {
            switch (user, authenticationContext) {
            case (.twitter(let record), .twitter(let authenticationContext)):
                guard let user = record.object(in: managedObjectContext),
                      let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
                else {
                    throw AppError.implicit(.badRequest)
                }
                let me = authentication.user
                return BlockAlertContext(
                    isBlocking: user.blockingBy.contains(me),
                    name: user.name
                )
                
            case (.mastodon(let record), .mastodon(let authenticationContext)):
                guard let user = record.object(in: managedObjectContext),
                      let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
                else {
                    throw AppError.implicit(.badRequest)
                }
                let me = authentication.user
                return BlockAlertContext(
                    isBlocking: user.blockingBy.contains(me),
                    name: user.name
                )
                
            default:
                throw AppError.implicit(.badRequest)
            }
        }
        
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        
        let alertControllerTitle = blockAlertContext.isBlocking ? L10n.Common.Alerts.UnblockUserConfirm.title(blockAlertContext.name) : L10n.Common.Alerts.BlockUserConfirm.title(blockAlertContext.name)
        let alertController = UIAlertController(
            title: alertControllerTitle,
            message: nil,
            preferredStyle: .alert
        )
        
        let blockActionTitle = blockAlertContext.isBlocking ? L10n.Common.Controls.Friendship.Actions.unblock : L10n.Common.Controls.Friendship.Actions.block
        let blockActionStyle: UIAlertAction.Style = blockAlertContext.isBlocking ? .default : .destructive
        let blockAction = UIAlertAction(
            title: blockActionTitle,
            style: blockActionStyle
        ) { [weak provider] _ in
            guard let provider = provider else { return }
            
            Task {
                do {
                    impactFeedbackGenerator.impactOccurred()
                    try await provider.context.apiService.block(
                        user: user,
                        authenticationContext: authenticationContext
                    )
                    notificationFeedbackGenerator.notificationOccurred(.success)
                } catch {
                    notificationFeedbackGenerator.notificationOccurred(.error)
                }
            }
        }
        alertController.addAction(blockAction)
        
        let cancelAction = UIAlertAction.cancel
        alertController.addAction(cancelAction)
        
        return alertController
    }
    
}
