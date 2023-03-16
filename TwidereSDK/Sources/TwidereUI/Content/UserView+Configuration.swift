//
//  UserView+Configuration.swift
//  
//
//  Created by MainasuK on 2022-7-1.
//

import Foundation
import Combine
import SwiftUI
import CoreDataStack
import TwidereCore
import TwidereAsset
import Meta
import MastodonSDK

extension UserView {
    public struct ConfigurationContext {
        public let authContext: AuthContext
        public let listMembershipViewModel: ListMembershipViewModel?
        
        public init(
            authContext: AuthContext,
            listMembershipViewModel: ListMembershipViewModel?
        ) {
            self.authContext = authContext
            self.listMembershipViewModel = listMembershipViewModel
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
        // userAuthenticationContext
        viewModel.userAuthenticationContext = user.twitterAuthentication.flatMap {
            AuthenticationContext(authenticationIndex: $0.authenticationIndex, secret: AppSecret.default.secret)
        }
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
        // userAuthenticationContext
        viewModel.userAuthenticationContext = user.mastodonAuthentication.flatMap {
            AuthenticationContext(authenticationIndex: $0.authenticationIndex, secret: AppSecret.default.secret)
        }
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
        
        switch type {
        case .followRequest:
            setFollowRequestControlDisplay()
        default:
            break
        }
        
        notification.publisher(for: \.isFollowRequestBusy)
            .assign(to: \.isFollowRequestBusy, on: viewModel)
            .store(in: &disposeBag)
    }
}


