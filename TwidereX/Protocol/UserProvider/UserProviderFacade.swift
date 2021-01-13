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
import SwiftMessages

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
        let userID = twitterUser.id
        var children: [UIMenuElement] = []
        
        let muteAction = UIAction(
            title: muted ? L10n.Common.Controls.Friendship.Actions.unmute : L10n.Common.Controls.Actions.confirm,
            image: muted ? UIImage(systemName: "speaker") : UIImage(systemName: "speaker.slash"),
            discoverabilityTitle: muted ? nil : L10n.Common.Controls.Friendship.muteUser(username),
            attributes: muted ? [] : .destructive,
            state: .off
        ) { [weak dependency] _ in
            guard let dependency = dependency else { return }
            guard let activeTwitterAuthenticationBox = dependency.context.authenticationService.activeTwitterAuthenticationBox.value else { return }
            dependency.context.apiService.toggleMute(
                for: twitterUser,
                activeTwitterAuthenticationBox: activeTwitterAuthenticationBox
            )
            .sink { completion in
                switch completion {
                case .failure:
                    DispatchQueue.main.async {
                        var config = SwiftMessages.defaultConfig
                        config.duration = .seconds(seconds: 3)
                        config.interactiveHide = true
                        let bannerView = NotifyBannerView()
                        bannerView.configure(for: .warning)
                        let title = muted ? L10n.Common.Alerts.FailedToUnmuteUser.title(username) : L10n.Common.Alerts.FailedToMuteUser.title(username)
                        bannerView.titleLabel.text = title
                        let message = muted ? L10n.Common.Alerts.FailedToUnmuteUser.message : L10n.Common.Alerts.FailedToMuteUser.message
                        bannerView.messageLabel.text = message
                        SwiftMessages.show(config: config, view: bannerView)
                    }
                case .finished:
                    DispatchQueue.main.async {
                        var config = SwiftMessages.defaultConfig
                        config.duration = .seconds(seconds: 3)
                        config.interactiveHide = true
                        let bannerView = NotifyBannerView()
                        bannerView.configure(for: .normal)
                        let title = muted ? L10n.Common.Alerts.UnmuteUserSuccess.title(username) : L10n.Common.Alerts.MuteUserSuccess.title(username)
                        bannerView.titleLabel.text = title
                        bannerView.messageLabel.isHidden = true
                        SwiftMessages.show(config: config, view: bannerView)
                    }
                }
            } receiveValue: { response in
                // do nothing
            }
            .store(in: &dependency.context.disposeBag)
        }
        if muted {
            children.append(muteAction)
        } else {
            let muteMenu = UIMenu(title: L10n.Common.Controls.Friendship.Actions.mute, image: UIImage(systemName: "speaker.slash"), options: [], children: [muteAction])
            children.append(muteMenu)
        }
        
        let blockAction = UIAction(
            title: blocked ? L10n.Common.Controls.Friendship.Actions.unblock : L10n.Common.Controls.Actions.confirm,
            image: blocked ? UIImage(systemName: "circle") : UIImage(systemName: "nosign"),
            discoverabilityTitle: blocked ? nil : L10n.Common.Controls.Friendship.blockUser(username),
            attributes: blocked ? [] : .destructive,
            state: .off
        ) { [weak dependency] _ in
            guard let dependency = dependency else { return }
            guard let activeTwitterAuthenticationBox = dependency.context.authenticationService.activeTwitterAuthenticationBox.value else { return }
            dependency.context.apiService.toggleBlock(
                for: twitterUser,
                activeTwitterAuthenticationBox: activeTwitterAuthenticationBox
            )
            .sink { completion in
                switch completion {
                case .failure:
                    DispatchQueue.main.async {
                        var config = SwiftMessages.defaultConfig
                        config.duration = .seconds(seconds: 3)
                        config.interactiveHide = true
                        let bannerView = NotifyBannerView()
                        bannerView.configure(for: .warning)
                        let title = blocked ? L10n.Common.Alerts.FailedToUnblockUser.title(username) : L10n.Common.Alerts.FailedToBlockUser.title(username)
                        bannerView.titleLabel.text = title
                        let message = muted ? L10n.Common.Alerts.FailedToUnblockUser.message : L10n.Common.Alerts.FailedToBlockUser.message
                        bannerView.messageLabel.text = message
                        SwiftMessages.show(config: config, view: bannerView)
                    }
                case .finished:
                    DispatchQueue.main.async {
                        var config = SwiftMessages.defaultConfig
                        config.duration = .seconds(seconds: 3)
                        config.interactiveHide = true
                        let bannerView = NotifyBannerView()
                        bannerView.configure(for: .normal)
                        let title = blocked ? L10n.Common.Alerts.UnblockUserSuccess.title(username) : L10n.Common.Alerts.BlockUserSuccess.title(username)
                        bannerView.titleLabel.text = title
                        bannerView.messageLabel.isHidden = true
                        SwiftMessages.show(config: config, view: bannerView)
                    }
                }
            } receiveValue: { response in
                // do nothing
            }
            .store(in: &dependency.context.disposeBag)
        }
        if blocked {
            children.append(blockAction)
        } else {
            let blockMenu = UIMenu(title: L10n.Common.Controls.Friendship.Actions.block, image: UIImage(systemName: "nosign"), identifier: nil, options: [], children: [blockAction])
            children.append(blockMenu)
            
        }
        
        let reportMenu = UIMenu(title: L10n.Common.Controls.Friendship.Actions.report, image: UIImage(systemName: "flag"), identifier: nil, options: .destructive, children: [
            // TODO: L10n.Common.Controls.Friendship.Actions.report
            UIAction(title: L10n.Common.Controls.Actions.confirm, image: UIImage(systemName: "flag"), identifier: nil, discoverabilityTitle: nil, attributes: .destructive, state: .off) { [weak dependency] _ in
                guard let dependency = dependency else { return }
                guard let activeTwitterAuthenticationBox = dependency.context.authenticationService.activeTwitterAuthenticationBox.value else { return }
                dependency.context.apiService.userReportForSpam(
                    userID: userID,
                    performBlock: false,
                    twitterAuthenticationBox: activeTwitterAuthenticationBox
                )
                .sink { completion in
                    switch completion {
                    case .failure:
                        DispatchQueue.main.async {
                            var config = SwiftMessages.defaultConfig
                            config.duration = .seconds(seconds: 3)
                            config.interactiveHide = true
                            let bannerView = NotifyBannerView()
                            bannerView.configure(for: .warning)
                            bannerView.titleLabel.text = L10n.Common.Alerts.FailedToReportUser.title(username)
                            bannerView.messageLabel.text = L10n.Common.Alerts.FailedToReportUser.message
                            SwiftMessages.show(config: config, view: bannerView)
                        }
                    case .finished:
                        DispatchQueue.main.async {
                            var config = SwiftMessages.defaultConfig
                            config.duration = .seconds(seconds: 3)
                            config.interactiveHide = true
                            let bannerView = NotifyBannerView()
                            bannerView.configure(for: .normal)
                            bannerView.titleLabel.text = L10n.Common.Alerts.ReportUserSuccess.title(username)
                            bannerView.messageLabel.isHidden = true
                            SwiftMessages.show(config: config, view: bannerView)
                        }
                    }
                } receiveValue: { response in
                    
                }
                .store(in: &dependency.context.disposeBag)
            }
//            UIAction(title: L10n.Common.Controls.Friendship.Actions.reportAndBlock, image: UIImage(systemName: "flag.badge.ellipsis"), identifier: nil, discoverabilityTitle: nil, attributes: .destructive, state: .off) { [weak dependency] _ in
//                guard let dependency = dependency else { return }
//                guard let activeTwitterAuthenticationBox = dependency.context.authenticationService.activeTwitterAuthenticationBox.value else { return }
//                dependency.context.apiService.userReportForSpam(
//                    userID: userID,
//                    performBlock: true,
//                    twitterAuthenticationBox: activeTwitterAuthenticationBox
//                )
//                .sink { completion in
//
//                } receiveValue: { response in
//
//                }
//                .store(in: &dependency.context.disposeBag)
//            }
        ])
        children.append(reportMenu)

        return UIMenu(title: "", options: [], children: children)
    }
    
}
