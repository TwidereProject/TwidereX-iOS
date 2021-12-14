//
//  DataSourceFacade+Status.swift
//  DataSourceFacade+Status
//
//  Created by Cirno MainasuK on 2021-9-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import AppShared
import TwidereCore
import TwidereUI
import TwidereComposeUI

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
                    dateTimeProvider: DateTimeSwiftProvider(),
                    twitterTextProvider: OfficialTwitterTextProvider()
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
        try await provider.context.managedObjectContext.performChanges {
            guard let object = status.object(in: provider.context.managedObjectContext) else { return }
            switch object {
            case .twitter:
                break
            case .mastodon(let status):
                status.update(isContentReveal: !status.isContentReveal)
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
        try await provider.context.managedObjectContext.performChanges {
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
