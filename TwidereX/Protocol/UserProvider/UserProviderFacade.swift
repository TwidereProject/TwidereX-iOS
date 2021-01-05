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
    
    static func toggleUserFriendship(provider: UserProvider, cell: UITableViewCell) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        // prepare authentication
        guard let activeTwitterAuthenticationBox = provider.context.authenticationService.activeTwitterAuthenticationBox.value else {
            assertionFailure()
            return Fail(error: APIService.APIError.implicit(.authenticationMissing)).eraseToAnyPublisher()
        }
        
        let sharedTwitterUser = provider
            .twitterUser(for: cell, indexPath: nil)
            .share()
            .eraseToAnyPublisher()
        
        let actionConfirmPublisher = sharedTwitterUser
            .map { twitterUser -> AnyPublisher<Bool, Never> in
                Future<Bool, Never> { promise in
                    guard let twitterUser = twitterUser else {
                        promise(.success(false))
                        return
                    }
                    
                    let requestTwitterUserID = activeTwitterAuthenticationBox.twitterUserID
                    let isPending = (twitterUser.followRequestSentFrom ?? Set()).contains(where: { $0.id == requestTwitterUserID })
                    let isFollowing = (twitterUser.followingFrom ?? Set()).contains(where: { $0.id == requestTwitterUserID })
                    
                    if isPending || isFollowing {
                        let name = twitterUser.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let message = isPending ? L10n.Common.Alerts.CancelFollowRequest.message(name) : L10n.Common.Alerts.UnfollowUser.message(name)
                        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
                        let confirmAction = UIAlertAction(title: L10n.Common.Controls.Actions.confirm, style: .destructive) { _ in
                            promise(.success(true))
                        }
                        let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel) { _ in
                            promise(.success(false))
                        }
                        alertController.addAction(confirmAction)
                        alertController.addAction(cancelAction)
                        alertController.popoverPresentationController?.sourceView = cell
                        DispatchQueue.main.async { [weak provider] in
                            guard let provider = provider else { return }
                            provider.present(alertController, animated: true, completion: nil)
                        }
                    } else {
                        promise(.success(true))
                    }
                }
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
        
        return _toggleUserFriendship(
            provider: provider,
            activeTwitterAuthenticationBox: activeTwitterAuthenticationBox,
            twitterUser: sharedTwitterUser,
            actionConfirmPublisher: actionConfirmPublisher
        )
    }
    
    private static func _toggleUserFriendship(
        provider: UserProvider,
        activeTwitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox,
        twitterUser: AnyPublisher<TwitterUser?, Never>,
        actionConfirmPublisher: AnyPublisher<Bool, Never>
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        return Publishers.CombineLatest(
            twitterUser.eraseToAnyPublisher(),
            actionConfirmPublisher.eraseToAnyPublisher()
        )
        .compactMap { twitterUser, isActionConfirm -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error>? in
            guard let twitterUser = twitterUser, isActionConfirm else {
                return nil
            }

            return provider.context.apiService.toggleFriendship(
                for: twitterUser,
                activeTwitterAuthenticationBox: activeTwitterAuthenticationBox
            )
        }
        .setFailureType(to: Error.self)
        .switchToLatest()
        .eraseToAnyPublisher()
    }
    
}
