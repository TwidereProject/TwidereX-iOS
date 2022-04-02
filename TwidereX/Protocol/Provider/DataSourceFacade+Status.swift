//
//  DataSourceFacade+Status.swift
//  DataSourceFacade+Status
//
//  Created by Cirno MainasuK on 2021-9-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import AppShared
import TwidereCore
import TwidereUI
import TwidereComposeUI
import SwiftMessages

extension DataSourceFacade {
    @MainActor
    static func responseToStatusToolbar(
        provider: DataSourceProvider,
        status: StatusRecord,
        action: StatusToolbar.Action,
        sender: UIButton,
        authenticationContext: AuthenticationContext
    ) async {
        switch action {
        case .reply:
            guard let status = status.object(in: provider.context.managedObjectContext) else {
                assertionFailure()
                return
            }
            let composeViewModel = ComposeViewModel(context: provider.context)
            let composeContentViewModel = ComposeContentViewModel(
                inputContext: .reply(status: status),
                configurationContext: ComposeContentViewModel.ConfigurationContext(
                    apiService: provider.context.apiService,
                    authenticationService: provider.context.authenticationService,
                    mastodonEmojiService: provider.context.mastodonEmojiService,
                    statusViewConfigureContext: .init(
                        dateTimeProvider: DateTimeSwiftProvider(),
                        twitterTextProvider: OfficialTwitterTextProvider(),
                        authenticationContext: provider.context.authenticationService.$activeAuthenticationContext
                    )
                )
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
                    authenticationContext: authenticationContext
                )
            } catch {
                provider.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update repost failure: \(error.localizedDescription)")
            }
        case .like:
            do {
                try await DataSourceFacade.responseToStatusLikeAction(
                    provider: provider,
                    status: status,
                    authenticationContext: authenticationContext
                )
            } catch {
                provider.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update like failure: \(error.localizedDescription)")
            }
        case .menu:
            // media menu button trigger this
            await DataSourceFacade.responseToStatusShareAction(
                provider: provider,
                status: status,
                button: sender
            )
        }   // end switch action
    }
}

extension DataSourceFacade {

    static func responseToExpandContentAction(
        provider: DataSourceProvider,
        target: StatusTarget,
        status: StatusRecord
    ) async throws {
        let _redirectRecord = await DataSourceFacade.status(
            managedObjectContext: provider.context.managedObjectContext,
            status: status,
            target: target
        )
        guard let redirectRecord = _redirectRecord else { return }
        
        try await responseToExpandContentAction(
            provider: provider,
            status: redirectRecord
        )
    }
    
    @MainActor
    static func responseToExpandContentAction(
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
        provider: DataSourceProvider,
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
    }
    
    @MainActor
    static func responseToToggleMediaSensitiveAction(
        provider: DataSourceProvider,
        status: StatusRecord
    ) async throws {
        try await provider.context.backgroundManagedObjectContext.performChanges {
            guard let object = status.object(in: provider.context.managedObjectContext) else { return }
            switch object {
            case .twitter:
                break
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
    ) async throws {
        let _redirectRecord = await DataSourceFacade.status(
            managedObjectContext: provider.context.managedObjectContext,
            status: status,
            target: target
        )
        guard let redirectRecord = _redirectRecord else { return }
        
        try await responseToRemoveStatusAction(
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
    ) async throws {
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
