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
import Meta

extension UserView {
    final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        
        let relationshipViewModel = RelationshipViewModel()
        
        @Published var platform: Platform = .none
        
        @Published var avatarImageURL: URL?
        @Published var name: MetaContent? = PlaintextMetaContent(string: " ")
        @Published var username: String? = " "
    }
}

extension UserView.ViewModel {
    func bind(userView: UserView) {
        // avatar
        $avatarImageURL
            .sink { url in
                let configuration = AvatarImageView.Configuration(url: url)
                userView.authorProfileAvatarView.avatarButton.avatarImageView.configure(configuration: configuration)
            }
            .store(in: &disposeBag)
//        // badge
//        $platform
//            .sink { platform in
//                switch platform {
//                case .twitter:
//                    userView.badgeImageView.image = Asset.Badge.twitter.image
//                    userView.setBadgeDisplay()
//                case .mastodon:
//                    userView.badgeImageView.image = Asset.Badge.mastodon.image
//                    userView.setBadgeDisplay()
//                case .none:
//                    break
//                }
//            }
//            .store(in: &disposeBag)
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
            .assign(to: \.text, on: userView.usernameLabel)
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
    }
    
}

extension UserView {
    func configure(user: UserObject, me: UserObject?) {
        switch user {
        case .twitter(let user):
            configure(twitterUser: user)
        case .mastodon(let user):
            configure(mastodonUser: user)
        }
        
        viewModel.relationshipViewModel.user = user
        viewModel.relationshipViewModel.me = me
    }
}

extension UserView {
    private func configure(twitterUser user: TwitterUser) {
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
            .map { "@\($0)" as String? }
            .assign(to: \.username, on: viewModel)
            .store(in: &disposeBag)
    }
    
}

extension UserView {
    private func configure(mastodonUser user: MastodonUser) {
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
        user.publisher(for: \.username)
            .map { "@\($0)" as String? }
            .assign(to: \.username, on: viewModel)
            .store(in: &disposeBag)
    }
}
