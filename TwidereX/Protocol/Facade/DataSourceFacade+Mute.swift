//
//  DataSourceFacade+Mute.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

extension DataSourceFacade {
    @MainActor
    static func presentUserMuteAlert(
        provider: DataSourceProvider,
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()

        do {
            let alertController = try await DataSourceFacade.createUserMuteAlert(
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
    
    private struct MuteAlertContext {
        let isMuting: Bool
        let name: String
    }
    
    @MainActor
    static func createUserMuteAlert(
        provider: DataSourceProvider,
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async throws -> UIAlertController {
        let managedObjectContext = provider.context.managedObjectContext
        let muteAlertContext: MuteAlertContext = try await managedObjectContext.perform {
            switch (user, authenticationContext) {
            case (.twitter(let record), .twitter(let authenticationContext)):
                guard let user = record.object(in: managedObjectContext),
                      let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
                else {
                    throw AppError.implicit(.badRequest)
                }
                let me = authentication.user
                return MuteAlertContext(
                    isMuting: user.mutingBy.contains(me),
                    name: user.name
                )
                
            case (.mastodon(let record), .mastodon(let authenticationContext)):
                guard let user = record.object(in: managedObjectContext),
                      let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
                else {
                    throw AppError.implicit(.badRequest)
                }
                let me = authentication.user
                return MuteAlertContext(
                    isMuting: user.mutingBy.contains(me),
                    name: user.name
                )
                
            default:
                throw AppError.implicit(.badRequest)
            }
        }
        
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        
        let alertControllerTitle = muteAlertContext.isMuting ? L10n.Common.Alerts.UnmuteUserConfirm.title(muteAlertContext.name) : L10n.Common.Alerts.MuteUserConfirm.title(muteAlertContext.name)
        let alertController = UIAlertController(
            title: alertControllerTitle,
            message: nil,
            preferredStyle: .alert
        )
        
        let muteActionTitle = muteAlertContext.isMuting ? L10n.Common.Controls.Friendship.Actions.unmute : L10n.Common.Controls.Friendship.Actions.mute
        let muteActionStyle: UIAlertAction.Style = muteAlertContext.isMuting ? .default : .destructive
        let muteAction = UIAlertAction(
            title: muteActionTitle,
            style: muteActionStyle
        ) { [weak provider] _ in
            guard let provider = provider else { return }
            
            Task {
                do {
                    impactFeedbackGenerator.impactOccurred()
                    try await provider.context.apiService.mute(
                        user: user,
                        authenticationContext: authenticationContext
                    )
                    notificationFeedbackGenerator.notificationOccurred(.success)
                } catch {
                    notificationFeedbackGenerator.notificationOccurred(.error)
                }
            }
        }
        alertController.addAction(muteAction)
        
        let cancelAction = UIAlertAction.cancel
        alertController.addAction(cancelAction)
        
        return alertController
    }
    
}
