//
//  FriendshipListSection.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import CoreData
import CoreDataStack
import SwiftMessages

enum FriendshipListSection: Equatable, Hashable {
    case main
}

extension MediaSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        context: AppContext,
        managedObjectContext: NSManagedObjectContext
    ) -> UITableViewDiffableDataSource<FriendshipListSection, Item> {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .twitterUser(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: FriendshipTableViewCell.self), for: indexPath) as! FriendshipTableViewCell
                managedObjectContext.performAndWait {
                    let twitterUser = managedObjectContext.object(with: objectID) as! TwitterUser
                    MediaSection.configure(cell: cell, twitterUser: twitterUser, context: context)
                    cell.menuButtonDidPressedPublisher
                        .sink { [weak cell] in
                            guard let cell = cell else { return }
                            MediaSection.configureMenu(cell: cell, for: twitterUser, context: context)
                        }
                        .store(in: &cell.disposeBag)
                }
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.isHidden = false
                cell.activityIndicatorView.startAnimating()
                cell.loadMoreButton.isHidden = true
                return cell
            default:
                assertionFailure()
                return nil
            }
        }
    }
}

extension MediaSection {
    static func configure(cell: FriendshipTableViewCell, twitterUser: TwitterUser, context: AppContext) {
        cell.userBriefInfoView.configure(avatarImageURL: twitterUser.avatarImageURL(), verified: twitterUser.verified)
        cell.userBriefInfoView.lockImageView.isHidden = !twitterUser.protected
        cell.userBriefInfoView.nameLabel.text = twitterUser.name
        cell.userBriefInfoView.usernameLabel.text = "@" + twitterUser.username
        
        let followersCount = twitterUser.metrics?.followersCount.flatMap { String($0.intValue) } ?? "-"
        cell.userBriefInfoView.detailLabel.text = "\(L10n.Common.Controls.Friendship.followers.capitalized): \(followersCount)"
        
        configureMenu(cell: cell, for: twitterUser, context: context)
    }
}

extension MediaSection {
    
    static func configureMenu(cell: FriendshipTableViewCell, for twitterUser: TwitterUser, context: AppContext) {
        // not display menu button for self
        guard let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value,
              twitterUser.id != activeTwitterAuthenticationBox.twitterUserID else {
            cell.userBriefInfoView.menuButton.isHidden = true
            return
        }
        
        if #available(iOS 14.0, *) {
            let deferredFriendshipMenuItem = MediaSection.deferredFriendshipMenuItem(of: cell.userBriefInfoView.menuButton, for: twitterUser, context: context)
            cell.userBriefInfoView.menuButton.menu = UIMenu(title: "", options: .displayInline, children: [deferredFriendshipMenuItem])
            cell.userBriefInfoView.menuButton.showsMenuAsPrimaryAction = true
            cell.userBriefInfoView.menuButton.isHidden = false
        } else {
            // no menu support for earlier versions
            cell.userBriefInfoView.menuButton.isHidden = true
        }
    }
    
    @available(iOS 14.0, *)
    static func deferredFriendshipMenuItem(of button: UIButton, for twitterUser: TwitterUser, context: AppContext) -> UIDeferredMenuElement {
        UIDeferredMenuElement { [weak button] elementProvider in
            let errorAction = UIAction(title: L10n.Common.Alerts.FailedToLoad.title, image: nil, identifier: nil, discoverabilityTitle: L10n.Common.Alerts.FailedToLoad.message, attributes: .disabled, state: .off) { _ in }
            guard let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
                elementProvider([errorAction])
                return
            }
            
            // TODO: handle blocked_by
            context.apiService.friendship(twitterUserObjectID: twitterUser.objectID, twitterAuthenticationBox: activeTwitterAuthenticationBox)
                .receive(on: DispatchQueue.main)
                .sink { friendshipCompletion in
                    switch friendshipCompletion {
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch friendship for user %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, twitterUser.id, error.localizedDescription)
                        elementProvider([errorAction])
                    case .finished:
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch friendship for user %s success", ((#file as NSString).lastPathComponent), #line, #function, twitterUser.id)
                    }
                } receiveValue: { response in
                    let relationship = response.value
                    let menuTitle = relationship.source.followedBy ? L10n.Common.Controls.Friendship.userIsFollowingYou(twitterUser.name) : L10n.Common.Controls.Friendship.userIsNotFollowingYou(twitterUser.name)
                    let unfollowConfirmAction = UIAction(title: L10n.Common.Controls.Actions.confirm, image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .destructive, state: .off, handler: { _ in
                        let configuration = FriendshipBannerConfiguration(
                            successInfo: FriendshipBannerConfiguration.Info(title: L10n.Common.Alerts.UnfollowingSuccess.title, message: ""),
                            failureInfo: FriendshipBannerConfiguration.Info(title: L10n.Common.Alerts.FailedToUnfollowing.title, message: L10n.Common.Alerts.FailedToUnfollowing.message)
                        )
                        MediaSection.toggleFriendship(
                            context: context,
                            twitterUser: twitterUser,
                            friendshipBannerConfiguration: configuration
                        )
                    })
                    
                    if relationship.source.followingRequested {
                        let cancelFollowRequestMenu = UIMenu(title: L10n.Common.Alerts.CancelFollowRequest.message(twitterUser.name), image: nil, identifier: nil, options: .destructive, children: [unfollowConfirmAction])
                        elementProvider([cancelFollowRequestMenu])
                    } else {
                        if relationship.source.following {
                            let unfollowMenu = UIMenu(title: L10n.Common.Controls.Friendship.Actions.unfollow, image: UIImage(systemName: "person.crop.circle.badge.minus"), identifier: nil, options: .destructive, children: [unfollowConfirmAction])
                            let menu = UIMenu(title: menuTitle, image: nil, identifier: nil, options: .displayInline, children: [unfollowMenu])
                            elementProvider([menu])
                            button?.menu = menu
                        } else {
                            let followingAction = UIAction(title: L10n.Common.Controls.Friendship.Actions.follow, image: nil, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { _ in
                                let configuration = FriendshipBannerConfiguration(
                                    successInfo: FriendshipBannerConfiguration.Info(title: L10n.Common.Alerts.FollowingSuccess.title, message: ""),
                                    failureInfo: FriendshipBannerConfiguration.Info(title: L10n.Common.Alerts.FailedToFollowing.title, message: L10n.Common.Alerts.FailedToFollowing.message)
                                )
                                MediaSection.toggleFriendship(
                                    context: context,
                                    twitterUser: twitterUser,
                                    friendshipBannerConfiguration: configuration
                                )
                            }
                            let menu = UIMenu(title: menuTitle, image: nil, identifier: nil, options: .displayInline, children: [followingAction])
                            elementProvider([menu])
                            button?.menu = menu
                        }
                    }
                }
                .store(in: &context.disposeBag)
        }
    }
    
}

extension MediaSection {

    private struct FriendshipBannerConfiguration {
        let successInfo: Info
        let failureInfo: Info
        
        struct Info {
            let title: String
            let message: String
        }
    }
    
    private static func toggleFriendship(
        context: AppContext,
        twitterUser: TwitterUser,
        friendshipBannerConfiguration: FriendshipBannerConfiguration
    ) {
        UserProviderFacade
            .toggleUserFriendship(context: context, twitterUser: twitterUser)
            .sink { completion in
                switch completion {
                case .failure:
                    var config = SwiftMessages.defaultConfig
                    config.duration = .seconds(seconds: 3)
                    config.interactiveHide = true
                    let bannerView = NotifyBannerView()
                    bannerView.configure(for: .warning)
                    bannerView.titleLabel.text = friendshipBannerConfiguration.failureInfo.title
                    bannerView.messageLabel.text = friendshipBannerConfiguration.failureInfo.message
                    DispatchQueue.main.async {
                        SwiftMessages.show(config: config, view: bannerView)
                    }
                case .finished:
                    var config = SwiftMessages.defaultConfig
                    config.duration = .seconds(seconds: 3)
                    config.interactiveHide = true
                    let bannerView = NotifyBannerView()
                    bannerView.configure(for: .normal)
                    bannerView.titleLabel.text = friendshipBannerConfiguration.successInfo.title
                    bannerView.messageLabel.isHidden = true
                    DispatchQueue.main.async {
                        SwiftMessages.show(config: config, view: bannerView)
                    }
                }
            } receiveValue: { response in
                // do nothing
            }
            .store(in: &context.disposeBag)
    }

}
