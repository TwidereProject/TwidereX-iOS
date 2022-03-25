//
//  UserView+ViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import SwiftUI
import CoreDataStack
import TwidereCommon
import TwidereCore
import TwidereAsset
import Meta
import MastodonSDK

extension UserView {
    public final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        var observations = Set<NSKeyValueObservation>()

        let relationshipViewModel = RelationshipViewModel()
        
        @Published public var platform: Platform = .none
        @Published public var authenticationContext: AuthenticationContext?       // me

        @Published public var header: Header = .none
        
        @Published public var userIdentifier: UserIdentifier? = nil
        @Published public var avatarImageURL: URL?
        @Published public var avatarBadge: AvatarBadge = .none
        // TODO: verified | bot
        
        @Published public var name: MetaContent? = PlaintextMetaContent(string: " ")
        @Published public var username: String?
        
        @Published public var protected: Bool = false
        
        @Published public var followerCount: Int?
        
        public var listMembershipViewModel: ListMembershipViewModel?
        @Published public var listOwnerUserIdentifier: UserIdentifier? = nil
        @Published public var isListMember = false
        @Published public var isListMemberCandidate = false       // a.k.a isBusy
        @Published public var isMyList = false
        
        public enum Header {
            case none
            case notification(info: NotificationHeaderInfo)
        }
        
        public enum AvatarBadge {
            case none
            case platform
            case user   // verified | bot
        }
        
        init() {
            // isMyList
            Publishers.CombineLatest(
                $authenticationContext,
                $listOwnerUserIdentifier
            )
            .map { authenticationContext, userIdentifier -> Bool in
                guard let authenticationContext = authenticationContext else { return false }
                guard let userIdentifier = userIdentifier else { return false }
                return authenticationContext.userIdentifier == userIdentifier
            }
            .assign(to: &$isMyList)
        }
    }
}

extension UserView.ViewModel {
    public func bind(userView: UserView) {
        // avatar
        $avatarImageURL
            .sink { url in
                let configuration = AvatarImageView.Configuration(url: url)
                userView.authorProfileAvatarView.avatarButton.avatarImageView.configure(configuration: configuration)
            }
            .store(in: &disposeBag)
        Publishers.CombineLatest(
            $avatarBadge,
            $platform
        )
        .sink { avatarBadge, platform in
            switch avatarBadge {
            case .none:
                userView.authorProfileAvatarView.badge = .none
            case .platform:
                userView.authorProfileAvatarView.badge = {
                    switch platform {
                    case .none:         return .none
                    case .twitter:      return .circle(.twitter)
                    case .mastodon:     return .circle(.mastodon)
                    }
                }()
            case .user:
                userView.authorProfileAvatarView.badge = .none
            }
        }
        .store(in: &disposeBag)
        // badge
        UserDefaults.shared
            .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
                let avatarStyle = defaults.avatarStyle
                let animator = UIViewPropertyAnimator(duration: 0.3, timingParameters: UISpringTimingParameters())
                animator.addAnimations { [weak userView] in
                    guard let userView = userView else { return }
                    switch avatarStyle {
                    case .circle:
                        userView.authorProfileAvatarView.avatarStyle = .circle
                    case .roundedSquare:
                        userView.authorProfileAvatarView.avatarStyle = .roundedRect
                    }
                }
                animator.startAnimation()
            }
            .store(in: &observations)
        // header
        $header
            .sink { header in
                switch header {
                case .none:
                    return
                case .notification(let info):
                    userView.headerIconImageView.image = info.iconImage
                    userView.headerIconImageView.tintColor = info.iconImageTintColor
                    userView.headerTextLabel.setupAttributes(style: UserView.headerTextLabelStyle)
                    userView.headerTextLabel.configure(content: info.textMetaContent)
                    userView.setHeaderDisplay()
                }
            }
            .store(in: &disposeBag)
        // name
        $name
            .sink { content in
                guard let content = content else {
                    userView.nameLabel.reset()
                    return
                }
                userView.nameLabel.configure(content: content)
            }
            .store(in: &disposeBag)
        // username
        $username
            .map { username in
                return username.flatMap { "@\($0)" } ?? " "
            }
            .assign(to: \.text, on: userView.usernameLabel)
            .store(in: &disposeBag)
        // protected
        $protected
            .map { !$0 }
            .assign(to: \.isHidden, on: userView.lockImageView)
            .store(in: &disposeBag)
        // follower count
        $followerCount
            .sink { followerCount in
                let count = followerCount.flatMap { String($0) } ?? "-"
                userView.followerCountLabel.text = L10n.Common.Controls.ProfileDashboard.followers + ": " + count
            }
            .store(in: &disposeBag)
        // relationship
        relationshipViewModel.$optionSet
            .map { $0?.relationship(except: [.muting]) }
            .sink { relationship in
                guard let relationship = relationship else { return }
                userView.friendshipButton.configure(relationship: relationship)
                userView.friendshipButton.isHidden = relationship == .isMyself
            }
            .store(in: &disposeBag)

        // accessory
        switch userView.style {
        case .account:
            userView.menuButton.showsMenuAsPrimaryAction = true
            userView.menuButton.menu = {
                let children = [
                    UIAction(
                        title: L10n.Common.Controls.Actions.signOut,
                        image: UIImage(systemName: "person.crop.circle.badge.minus"),
                        attributes: .destructive,
                        state: .off
                    ) { [weak userView] _ in
                        guard let userView = userView else { return }
                        userView.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): sign out user…")
                        userView.delegate?.userView(userView, menuActionDidPressed: .signOut, menuButton: userView.menuButton)
                    }
                ]
                return UIMenu(title: "", image: nil, options: [], children: children)
            }()
                
        case .listMember:
            userView.menuButton.showsMenuAsPrimaryAction = true
            userView.menuButton.menu = {
                let children = [
                    UIAction(
                        title: L10n.Common.Controls.Actions.remove,
                        image: UIImage(systemName: "minus.circle"),
                        attributes: .destructive,
                        state: .off
                    ) { [weak userView] _ in
                        guard let userView = userView else { return }
                        userView.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): remove user…")
                        userView.delegate?.userView(userView, menuActionDidPressed: .remove, menuButton: userView.menuButton)
                    }
                ]
                return UIMenu(title: "", image: nil, options: [], children: children)
            }()
            $isMyList
                .map { !$0 }
                .assign(to: \.isHidden, on: userView.menuButton)
                .store(in: &disposeBag)
        case .addListMember:
            Publishers.CombineLatest(
                $isListMember,
                $isListMemberCandidate
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak userView] isMember, isMemberCandidate in
                guard let userView = userView else { return }
                let image = isMember ? UIImage(systemName: "minus.circle") : UIImage(systemName: "plus.circle")
                let tintColor = isMember ? UIColor.systemRed : Asset.Colors.hightLight.color
                userView.membershipButton.setImage(image, for: .normal)
                userView.membershipButton.tintColor = tintColor
                
                userView.membershipButton.alpha = isMemberCandidate ? 0 : 1
                userView.activityIndicatorView.isHidden = !isMemberCandidate
                userView.activityIndicatorView.startAnimating()
            }
            .store(in: &disposeBag)
                
        default:
            userView.menuButton.showsMenuAsPrimaryAction = true
            userView.menuButton.menu = nil
        }
    }
    
}

extension UserView {
    public struct ConfigurationContext {
        public let listMembershipViewModel: ListMembershipViewModel?
        public let authenticationContext: Published<AuthenticationContext?>.Publisher
        
        public init(
            listMembershipViewModel: ListMembershipViewModel?,
            authenticationContext: Published<AuthenticationContext?>.Publisher
        ) {
            self.listMembershipViewModel = listMembershipViewModel
            self.authenticationContext = authenticationContext
        }
    }
}

extension UserView {
    public func configure(
        user: UserObject,
        me: UserObject?,
        notification: NotificationObject?,
        configurationContext: ConfigurationContext
    ) {
        configurationContext.authenticationContext
            .assign(to: \.authenticationContext, on: viewModel)
            .store(in: &disposeBag)
        
        switch user {
        case .twitter(let user):
            configure(twitterUser: user)
        case .mastodon(let user):
            configure(mastodonUser: user)
        }
        
        if let notification = notification {
            configure(notification: notification)
        }
        
        viewModel.relationshipViewModel.user = user
        viewModel.relationshipViewModel.me = me
        
        viewModel.listMembershipViewModel = configurationContext.listMembershipViewModel
        if let listMembershipViewModel = configurationContext.listMembershipViewModel {
            listMembershipViewModel.$ownerUserIdentifier
                .assign(to: \.listOwnerUserIdentifier, on: viewModel)
                .store(in: &disposeBag)
        }
        
        // accessory
        switch style {
        case .addListMember:
            guard let listMembershipViewModel = configurationContext.listMembershipViewModel else {
                assertionFailure()
                break
            }
            let userRecord = user.asRecord
            listMembershipViewModel.$members
                .map { members in members.contains(userRecord) }
                .assign(to: \.isListMember, on: viewModel)
                .store(in: &disposeBag)
            listMembershipViewModel.$workingMembers
                .map { members in members.contains(userRecord) }
                .assign(to: \.isListMemberCandidate, on: viewModel)
                .store(in: &disposeBag)
        default:
            break
        }
    }
    
    public func configure(notification: NotificationObject) {
        switch notification {
        case .mastodon(let notification):
            configure(mastodonNotification: notification)
        }
    }
}

extension UserView {
    private func configure(twitterUser user: TwitterUser) {
        // platform
        viewModel.platform = .twitter
        // userIdentifier
        viewModel.userIdentifier = .twitter(.init(id: user.id))
        // avatar
        user.publisher(for: \.profileImageURL)
            .map { _ in user.avatarImageURL() }
            .assign(to: \.avatarImageURL, on: viewModel)
            .store(in: &disposeBag)
        // author name
        user.publisher(for: \.name)
            .map { PlaintextMetaContent(string: $0) }
            .assign(to: \.name, on: viewModel)
            .store(in: &disposeBag)
        // author username
        user.publisher(for: \.username)
            .map { $0 as String? }
            .assign(to: \.username, on: viewModel)
            .store(in: &disposeBag)
        // protected
        user.publisher(for: \.protected)
            .assign(to: \.protected, on: viewModel)
            .store(in: &disposeBag)
        // followersCount
        user.publisher(for: \.followersCount)
            .map { Int($0) }
            .assign(to: \.followerCount, on: viewModel)
            .store(in: &disposeBag)
    }
    
}

extension UserView {
    private func configure(mastodonUser user: MastodonUser) {
        // platform
        viewModel.platform = .mastodon
        // userIdentifier
        viewModel.userIdentifier = .mastodon(.init(domain: user.domain, id: user.id))
        // avatar
        Publishers.CombineLatest3(
            UserDefaults.shared.publisher(for: \.preferredStaticAvatar),
            user.publisher(for: \.avatar),
            user.publisher(for: \.avatarStatic)
        )
        .map { preferredStaticAvatar, avatar, avatarStatic in
            let string = preferredStaticAvatar ? (avatarStatic ?? avatar) : avatar
            return string.flatMap { URL(string: $0) }
        }
        .assign(to: \.avatarImageURL, on: viewModel)
        .store(in: &disposeBag)
        // author name
        Publishers.CombineLatest(
            user.publisher(for: \.displayName),
            user.publisher(for: \.emojis)
        )
        .map { _ in user.nameMetaContent }
        .assign(to: \.name, on: viewModel)
        .store(in: &disposeBag)
        // author username
        user.publisher(for: \.acct)
            .map { _ in user.acctWithDomain as String? }
            .assign(to: \.username, on: viewModel)
            .store(in: &disposeBag)
        // protected
        user.publisher(for: \.locked)
            .assign(to: \.protected, on: viewModel)
            .store(in: &disposeBag)
        // followersCount
        user.publisher(for: \.followersCount)
            .map { Int($0) }
            .assign(to: \.followerCount, on: viewModel)
            .store(in: &disposeBag)
    }
    
    private func configure(mastodonNotification notification: MastodonNotification) {
        let user = notification.account
        let type = notification.notificationType
        Publishers.CombineLatest(
            user.publisher(for: \.displayName),
            user.publisher(for: \.emojis)
        )
        .map { _ in
            guard let info = NotificationHeaderInfo(type: type, user: user) else {
                return .none
            }
            return ViewModel.Header.notification(info: info)
        }
        .assign(to: \.header, on: viewModel)
        .store(in: &disposeBag)
    }
}


