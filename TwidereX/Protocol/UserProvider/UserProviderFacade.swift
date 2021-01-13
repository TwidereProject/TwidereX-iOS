//
//  UserProviderFacade.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-5.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterAPI

enum UserProviderFacade {
    
    static func toggleUserFriendship(context: AppContext, twitterUser: TwitterUser) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        // prepare authentication
        guard let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
            assertionFailure()
            return Fail(error: APIService.APIError.implicit(.authenticationMissing)).eraseToAnyPublisher()
        }
        
        let twitterUser = Future<TwitterUser?, Error> { promise in
            promise(.success(twitterUser))
        }
        .eraseToAnyPublisher()
        
        return _toggleUserFriendship(
            context: context,
            activeTwitterAuthenticationBox: activeTwitterAuthenticationBox,
            twitterUser: twitterUser
        )
    }
    
    static func toggleUserFriendship(provider: UserProvider, sender: UIButton) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        // prepare authentication
        guard let activeTwitterAuthenticationBox = provider.context.authenticationService.activeTwitterAuthenticationBox.value else {
            assertionFailure()
            return Fail(error: APIService.APIError.implicit(.authenticationMissing)).eraseToAnyPublisher()
        }
        
        let twitterUser = _toggleUserFriendshipAlertControllerConfirmPublisher(
            provider: provider,
            activeTwitterAuthenticationBox: activeTwitterAuthenticationBox,
            twitterUser: provider.twitterUser().eraseToAnyPublisher(),
            sourceView: sender
        )
        
        return _toggleUserFriendship(
            provider: provider,
            activeTwitterAuthenticationBox: activeTwitterAuthenticationBox,
            twitterUser: twitterUser
        )
    }
    
    static func toggleUserFriendship(provider: UserProvider, cell: UITableViewCell) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        // prepare authentication
        guard let activeTwitterAuthenticationBox = provider.context.authenticationService.activeTwitterAuthenticationBox.value else {
            assertionFailure()
            return Fail(error: APIService.APIError.implicit(.authenticationMissing)).eraseToAnyPublisher()
        }
        
        let twitterUser = _toggleUserFriendshipAlertControllerConfirmPublisher(
            provider: provider,
            activeTwitterAuthenticationBox: activeTwitterAuthenticationBox,
            twitterUser: provider.twitterUser(for: cell, indexPath: nil).eraseToAnyPublisher(),
            sourceView: cell
        )
        
        return _toggleUserFriendship(
            provider: provider,
            activeTwitterAuthenticationBox: activeTwitterAuthenticationBox,
            twitterUser: twitterUser
        )
    }
    
    // Present Alert Controller to confirm cancel following action
    private static func _toggleUserFriendshipAlertControllerConfirmPublisher(
        provider: UserProvider,
        activeTwitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox,
        twitterUser: AnyPublisher<TwitterUser?, Never>,
        sourceView: UIView
    ) -> AnyPublisher<TwitterUser?, Error> {
        return twitterUser
            .setFailureType(to: Error.self)
            .flatMap { twitterUser -> Future<TwitterUser?, Error> in
                Future<TwitterUser?, Error> { promise in
                    guard let twitterUser = twitterUser else {
                        promise(.failure(APIService.APIError.implicit(.badRequest)))
                        return
                    }
                    
                    let requestTwitterUserID = activeTwitterAuthenticationBox.twitterUserID
                    let isPending = (twitterUser.followRequestSentFrom ?? Set()).contains(where: { $0.id == requestTwitterUserID })
                    let isFollowing = (twitterUser.followingBy ?? Set()).contains(where: { $0.id == requestTwitterUserID })
                    
                    if isPending || isFollowing {
                        let name = twitterUser.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let message = isPending ? L10n.Common.Alerts.CancelFollowRequest.message(name) : L10n.Common.Alerts.UnfollowUser.message(name)
                        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
                        let confirmAction = UIAlertAction(title: L10n.Common.Controls.Actions.confirm, style: .destructive) { _ in
                            promise(.success(twitterUser))
                        }
                        let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel) { _ in
                            promise(.success(nil))
                        }
                        alertController.addAction(confirmAction)
                        alertController.addAction(cancelAction)
                        alertController.popoverPresentationController?.sourceView = sourceView
                        DispatchQueue.main.async { [weak provider] in
                            guard let provider = provider else { return }
                            provider.present(alertController, animated: true, completion: nil)
                        }
                    } else {
                        promise(.success(twitterUser))
                    }
                }
            }
            .eraseToAnyPublisher()
    }
    
    private static func _toggleUserFriendship(
        provider: UserProvider,
        activeTwitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox,
        twitterUser: AnyPublisher<TwitterUser?, Error>
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        return _toggleUserFriendship(
            context: provider.context,
            activeTwitterAuthenticationBox: activeTwitterAuthenticationBox,
            twitterUser: twitterUser
        )
    }
    
    private static func _toggleUserFriendship(
        context: AppContext,
        activeTwitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox,
        twitterUser: AnyPublisher<TwitterUser?, Error>
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        twitterUser
            .compactMap { twitterUser -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error>? in
                guard let twitterUser = twitterUser else {
                    return nil
                }
                
                return context.apiService.toggleFriendship(
                    for: twitterUser,
                    activeTwitterAuthenticationBox: activeTwitterAuthenticationBox
                )
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
}

extension UserProviderFacade {

    @available(iOS 14.0, *)
    static func createMenuForUser(twitterUser: TwitterUser, muted: Bool, blocked: Bool, dependency: NeedsDependency) -> UIMenu {
        let username = "@" + twitterUser.username
        let muteMenu = UIMenu(title: L10n.Common.Controls.Friendship.Actions.mute, image: UIImage(systemName: "speaker.slash"), identifier: nil, options: [], children: [
            UIAction(title: L10n.Common.Controls.Actions.confirm, image: UIImage(systemName: "speaker.slash"), identifier: nil, discoverabilityTitle: L10n.Common.Controls.Friendship.muteUser(username), attributes: .destructive, state: .off) { _ in
                
            }
        ])
        let blockMenu = UIMenu(title: L10n.Common.Controls.Friendship.Actions.block, image: UIImage(systemName: "nosign"), identifier: nil, options: [], children: [
            UIAction(title: L10n.Common.Controls.Actions.confirm, image: UIImage(systemName: "nosign"), identifier: nil, discoverabilityTitle: L10n.Common.Controls.Friendship.blockUser(username), attributes: .destructive, state: .off) { _ in
                
            }
        ])
        let reportMenu = UIMenu(title: L10n.Common.Controls.Friendship.Actions.report, image: UIImage(systemName: "flag"), identifier: nil, options: .destructive, children: [
            UIAction(title: L10n.Common.Controls.Friendship.Actions.report, image: UIImage(systemName: "flag"), identifier: nil, discoverabilityTitle: nil, attributes: .destructive, state: .off) { _ in
                
            },
            UIAction(title: L10n.Common.Controls.Friendship.Actions.reportAndBlock, image: UIImage(systemName: "flag.badge.ellipsis"), identifier: nil, discoverabilityTitle: nil, attributes: .destructive, state: .off) { _ in
                
            }
        ])
        var children: [UIMenuElement] = [
            muteMenu
        ]
        return UIMenu(title: "", options: [], children: children)
    }
    
}
