//
//  DataSourceFacade+Status.swift
//  DataSourceFacade+Status
//
//  Created by Cirno MainasuK on 2021-9-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftMessages

extension DataSourceFacade {
    @MainActor
    static func responseToStatusToolbar(
        provider: DataSourceProvider & AuthContextProvider,
        viewModel: StatusView.ViewModel,
        statusToolbarViewModel: StatusToolbarView.ViewModel,
        status: StatusRecord,
        action: StatusToolbarView.Action
    ) async {
        defer {
            Task {
                await recordStatusHistory(
                    denpendency: provider,
                    status: status
                )
            }   // end Task
        }
        
        switch action {
        case .reply:
            guard let status = status.object(in: provider.context.managedObjectContext) else {
                assertionFailure()
                return
            }
            
            let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            impactFeedbackGenerator.impactOccurred()
            
            let composeViewModel = ComposeViewModel(context: provider.context)
            let composeContentViewModel = ComposeContentViewModel(
                context: provider.context,
                authContext: provider.authContext,
                kind: .reply(status: status)
            )
            provider.coordinator.present(
                scene: .compose(
                    viewModel: composeViewModel,
                    contentViewModel: composeContentViewModel
                ),
                from: provider,
                transition: .modal(animated: true, completion: nil)
            )
        case .repost:
            do {
                try await DataSourceFacade.responseToStatusRepostAction(
                    provider: provider,
                    status: status,
                    authenticationContext: provider.authContext.authenticationContext
                )
                
                // update store review count trigger
                UserDefaults.shared.storeReviewInteractTriggerCount += 1
            } catch {
                provider.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update repost failure: \(error.localizedDescription)")
            }
            
        case .quote:
            guard let status = status.object(in: provider.context.managedObjectContext) else {
                assertionFailure()
                return
            }
            
            let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            impactFeedbackGenerator.impactOccurred()
            
            let composeViewModel = ComposeViewModel(context: provider.context)
            let composeContentViewModel = ComposeContentViewModel(
                context: provider.context,
                authContext: provider.authContext,
                kind: .quote(status: status)
            )
            provider.coordinator.present(
                scene: .compose(
                    viewModel: composeViewModel,
                    contentViewModel: composeContentViewModel
                ),
                from: provider,
                transition: .modal(animated: true, completion: nil)
            )
        case .like:
            do {
                try await DataSourceFacade.responseToStatusLikeAction(
                    provider: provider,
                    status: status,
                    authenticationContext: provider.authContext.authenticationContext
                )
                
                // update store review count trigger
                UserDefaults.shared.storeReviewInteractTriggerCount += 1
            } catch {
                provider.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update like failure: \(error.localizedDescription)")
            }
        case .copyText:
            let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            impactFeedbackGenerator.impactOccurred()
            
            let plaintext = viewModel.content.string
            UIPasteboard.general.string = plaintext
        case .copyLink:
            let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            impactFeedbackGenerator.impactOccurred()
            
            let _link: String? = await provider.context.managedObjectContext.perform {
                guard let object = status.object(in: provider.context.managedObjectContext) else { return nil }
                guard let url = object.statusURL else { return nil }
                return url.absoluteString
            }
            guard let link = _link else { return }
            UIPasteboard.general.string = link
        case .shareLink:
            let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            impactFeedbackGenerator.impactOccurred()
            
            await DataSourceFacade.responseToStatusShareAction(
                provider: provider,
                status: status,
                sourceView: statusToolbarViewModel.menuButtonBackgroundView
            )
        case .saveMedia:
            let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
            
            let mediaViewModels = viewModel.mediaViewModels
            do {
                impactFeedbackGenerator.impactOccurred()
                for mediaViewModel in mediaViewModels {
                    guard let url = mediaViewModel.downloadURL else {
                        assertionFailure()
                        continue
                    }
                    try await provider.context.photoLibraryService.save(
                        source: .remote(url: url),
                        resourceType: {
                            switch mediaViewModel.mediaKind {
                            case .video:        return .video
                            case .animatedGIF:  return .video
                            case .photo:        return .photo
                            }
                        }()
                    )
                }
                provider.context.photoLibraryService.presentSuccessNotification(title: L10n.Common.Alerts.PhotoSaved.title)
                notificationFeedbackGenerator.notificationOccurred(.success)
            } catch {
                provider.context.photoLibraryService.presentFailureNotification(
                    error: error,
                    title: L10n.Common.Alerts.PhotoSaveFail.title,
                    message: L10n.Common.Alerts.PhotoSaveFail.message
                )
                notificationFeedbackGenerator.notificationOccurred(.error)
            }
        case .translate:
            let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            impactFeedbackGenerator.impactOccurred()
            do {
                try await DataSourceFacade.responseToStatusTranslate(
                    provider: provider,
                    status: status
                )
            } catch {
                assertionFailure(error.localizedDescription)
            }
        case .delete:
            await DataSourceFacade.responseToRemoveStatusAction(
                provider: provider,
                target: .status,
                status: status,
                authenticationContext: provider.authContext.authenticationContext
            )
        }   // end switch action
    }
}

extension DataSourceFacade {

    static func responseToToggleContentSensitiveAction(
        provider: DataSourceProvider & AuthContextProvider,
        target: StatusTarget,
        status: StatusRecord
    ) async throws {
        let _redirectRecord = await DataSourceFacade.status(
            managedObjectContext: provider.context.managedObjectContext,
            status: status,
            target: target
        )
        guard let redirectRecord = _redirectRecord else { return }
        
        try await responseToToggleContentSensitiveAction(
            provider: provider,
            status: redirectRecord
        )
        
        Task {
            await recordStatusHistory(
                denpendency: provider,
                status: status
            )
        }   // end Task
    }
    
    @MainActor
    static func responseToToggleContentSensitiveAction(
        provider: DataSourceProvider,
        status: StatusRecord
    ) async throws {
        let managedObjectContext = provider.context.managedObjectContext
        try await managedObjectContext.performChanges {
            guard let object = status.object(in: managedObjectContext) else { return }
            switch object {
            case .twitter:
                break
            case .mastodon(let status):
                status.update(isContentSensitiveToggled: !status.isContentSensitiveToggled)
            }
        }
    }
    
}

extension DataSourceFacade {

    static func responseToToggleMediaSensitiveAction(
        provider: DataSourceProvider & AuthContextProvider,
        target: StatusTarget,
        status: StatusRecord
    ) async throws {
        let _redirectRecord = await DataSourceFacade.status(
            managedObjectContext: provider.context.managedObjectContext,
            status: status,
            target: target
        )
        guard let redirectRecord = _redirectRecord else { return }
        
        try await responseToToggleMediaSensitiveAction(
            provider: provider,
            status: redirectRecord
        )
        
        Task {
            await recordStatusHistory(
                denpendency: provider,
                status: status
            )
        }   // end Task
    }
    
    @MainActor
    static func responseToToggleMediaSensitiveAction(
        provider: DataSourceProvider,
        status: StatusRecord
    ) async throws {
        // use same context on UI to make transient property trigger update
        let managedObjectContext = provider.context.managedObjectContext
        try await managedObjectContext.performChanges {
            guard let object = status.object(in: managedObjectContext) else { return }
            switch object {
            case .twitter(let status):
                status.update(isMediaSensitiveToggled: !status.isMediaSensitiveToggled)
            case .mastodon(let status):
                status.update(isMediaSensitiveToggled: !status.isMediaSensitiveToggled)
            }
        }
    }
    
}

extension DataSourceFacade {

    static func responseToRemoveStatusAction(
        provider: DataSourceProvider,
        target: StatusTarget,
        status: StatusRecord,
        authenticationContext: AuthenticationContext
    ) async {
        let _redirectRecord = await DataSourceFacade.status(
            managedObjectContext: provider.context.managedObjectContext,
            status: status,
            target: target
        )
        guard let redirectRecord = _redirectRecord else { return }
        
        await responseToRemoveStatusAction(
            provider: provider,
            status: redirectRecord,
            authenticationContext: authenticationContext
        )
    }
    
    @MainActor
    static func responseToRemoveStatusAction(
        provider: DataSourceProvider,
        status: StatusRecord,
        authenticationContext: AuthenticationContext
    ) async {
        let title: String = {
            switch status {
            case .twitter:      return L10n.Common.Alerts.DeleteTweetConfirm.title
            case .mastodon:     return L10n.Common.Alerts.DeleteTootConfirm.title
            }
        }()
        let message: String = {
            switch status {
            case .twitter:      return L10n.Common.Alerts.DeleteTweetConfirm.message
            case .mastodon:     return L10n.Common.Alerts.DeleteTootConfirm.message
            }
        }()
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let deleteAction = UIAlertAction(
            title: L10n.Common.Controls.Actions.delete,
            style: .destructive
        ) { [weak provider] _ in
            guard let provider = provider else { return }
            Task {
                do {
                    try await provider.context.apiService.deleteStatus(
                        record: status,
                        authenticationContext: authenticationContext
                    )
                    let title: String = {
                        switch status {
                        case .twitter:      return L10n.Common.Alerts.TweetDeleted.title
                        case .mastodon:     return L10n.Common.Alerts.TootDeleted.title
                        }
                    }()
                    presentSuccessBanner(title: title)
                } catch {
                    let title: String = {
                        switch status {
                        case .twitter:      return L10n.Common.Alerts.FailedToDeleteTweet.title
                        case .mastodon:     return L10n.Common.Alerts.FailedToDeleteToot.title
                        }
                    }()
                    let message: String = {
                        switch status {
                        case .twitter:      return L10n.Common.Alerts.FailedToDeleteTweet.message
                        case .mastodon:     return L10n.Common.Alerts.FailedToDeleteToot.message
                        }
                    }()
                    presentWarningBanner(title: title, message: message, error: error)
                }
            }   // end Task
        }
        alertController.addAction(deleteAction)
        let cancelAction = UIAlertAction.cancel
        alertController.addAction(cancelAction)
        provider.coordinator.present(
            scene: .alertController(alertController: alertController),
            from: provider,
            transition: .alertController(animated: true, completion: nil)
        )
    }
    
}
