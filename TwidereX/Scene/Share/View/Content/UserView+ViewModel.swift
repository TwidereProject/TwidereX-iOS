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
import Meta

extension UserView {
    final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        
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
    }
    
}

extension UserView {
    func configure(user: UserObject) {
        switch user {
        case .twitter(let user):
            configure(twitterUser: user)
        case .mastodon(let user):
            configure(mastodonUser: user)
        }
    }
}

extension UserView {
    func configure(twitterUser user: TwitterUser) {
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
    func configure(mastodonUser user: MastodonUser) {
        
    }
}
