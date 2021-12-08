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
//    struct StatusMenuContext {
//        let text: String
//        let url: String
//    }
//
//    static func createMenu(
//        dependency: NeedsDependency,
//        status: StatusRecord,
//        button: UIButton
//    ) -> UIMenu {
//        var children: [UIMenuElement] = [
//            UIAction(
//                title: L10n.Common.Controls.Status.Actions.copyText.capitalized,
//                image: UIImage(systemName: "doc.on.doc"),
//                identifier: nil,
//                discoverabilityTitle: nil,
//                attributes: [],
//                state: .off
//            ) { [weak dependency] _ in
//                guard let dependency = dependency else { return }
//                Task {
//                    let _text: String? = await dependency.context.managedObjectContext.perform {
//                        guard let object = status.object(in: dependency.context.managedObjectContext) else { return nil }
//                        return object.plaintextContent
//                    }
//                    guard let text = _text else { return }
//                    UIPasteboard.general.string = text
//                }
//            },
//            UIAction(
//                title: L10n.Common.Controls.Status.Actions.copyLink.capitalized,
//                image: UIImage(systemName: "link"),
//                identifier: nil,
//                discoverabilityTitle: nil,
//                attributes: [],
//                state: .off
//            ) { [weak dependency] _ in
//                guard let dependency = dependency else { return }
//                Task {
//                    let _url: URL? = await dependency.context.managedObjectContext.perform {
//                        guard let object = status.object(in: dependency.context.managedObjectContext) else { return nil }
//                        return object.statusURL
//                    }
//                    guard let url = _url else { return }
//                    UIPasteboard.general.string = url.absoluteString
//                }
//            },
//            UIAction(
//                title: L10n.Common.Controls.Status.Actions.shareLink.capitalized,
//                image: UIImage(systemName: "square.and.arrow.up"),
//                identifier: nil,
//                discoverabilityTitle: nil,
//                attributes: [],
//                state: .off
//            ) { [weak dependency, weak button] _ in
//                guard let sender = button else { return }
//                guard let dependency = dependency else { return }
//                Task {
//                    let activityViewController = await DataSourceFacade.createActivityViewController(
//                        dependency: dependency,
//                        status: status
//                    )
//                    await dependency.coordinator.present(
//                        scene: .activityViewController(activityViewController: activityViewController, sourceView: sender),
//                        from: nil,
//                        transition: .activityViewControllerPresent(animated: true, completion: nil)
//                    )
//                }
//            }
//        ]
//
////        if let activeTwitterAuthenticationBox = dependency.context.authenticationService.activeTwitterAuthenticationBox.value {
////            let activeTwitterUserID = activeTwitterAuthenticationBox.twitterUserID
////            if tweet.author.id == activeTwitterUserID || tweet.retweet?.author.id == activeTwitterUserID {
////                let deleteTweetAction = UIAction(title: L10n.Common.Controls.Actions.confirm, image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .destructive, state: .off) { [weak dependency] _ in
////                    guard let dependency = dependency else { return }
////                    guard let activeTwitterAuthenticationBox = dependency.context.authenticationService.activeTwitterAuthenticationBox.value else {
////                        return
////                    }
////                    dependency.context.apiService.delete(
////                        tweetObjectID: tweet.objectID,
////                        twitterAuthenticationBox: activeTwitterAuthenticationBox
////                    )
////                    .sink { completion in
////
////                    } receiveValue: { response in
////
////                    }
////                    .store(in: &dependency.context.disposeBag)
////                }
////                let deleteTweetMenu = UIMenu(title: L10n.Common.Controls.Status.Actions.deleteTweet.capitalized, image: UIImage(systemName: "trash"), identifier: nil, options: .destructive, children: [deleteTweetAction])
////                children.append(deleteTweetMenu)
////            }
////        }
//
//        return UIMenu(title: "", options: [], children: children)
//    }

}
