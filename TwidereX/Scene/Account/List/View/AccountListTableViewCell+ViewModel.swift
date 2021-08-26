//
//  AccountListTableViewCell+ViewModel.swift
//  AccountListTableViewCell+ViewModel
//
//  Created by Cirno MainasuK on 2021-8-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreDataStack

extension AccountListTableViewCell {
    final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        
        @Published var platform: Platform = .none
        
        @Published var avatarImageURL: URL?
        @Published var name: String?
        @Published var username: String?
        
        init() { }
    }
    
    func configure(viewModel: ViewModel) {
        // avatar
        viewModel.$avatarImageURL
            .sink { [weak self] url in
                guard let self = self else { return }
                let configuration = AvatarImageView.Configuration(url: url)
                self.userBriefInfoView.avatarImageView.configure(configuration: configuration)
            }
            .store(in: &disposeBag)
        // badge
        viewModel.$platform
            .sink { [weak self] platform in
                guard let self = self else { return }
                switch platform {
                case .twitter:
                    self.userBriefInfoView.badgeImageView.image = Asset.Badge.twitter.image
                    self.userBriefInfoView.setBadgeDisplay()
                case .mastodon:
                    self.userBriefInfoView.badgeImageView.image = Asset.Badge.mastodon.image
                    self.userBriefInfoView.setBadgeDisplay()
                case .none:
                    break
                }
            }
            .store(in: &disposeBag)
        // name
        viewModel.$name
            .assign(to: \.text, on: userBriefInfoView.nameLabel)
            .store(in: &disposeBag)
        // username
        viewModel.$username
            .assign(to: \.text, on: userBriefInfoView.detailLabel)
            .store(in: &disposeBag)
        
        // FIXME:
        userBriefInfoView.headerSecondaryLabel.isHidden = true
        
    }
}

extension AccountListTableViewCell.ViewModel {
    convenience init(authenticationIndex: AuthenticationIndex) {
        if let twitterUser = authenticationIndex.twitterAuthentication?.twitterUser {
            self.init(twitterUser: twitterUser)
        } else if let mastodonUser = authenticationIndex.mastodonAuthentication?.mastodonUser {
            self.init(mastodonUser: mastodonUser)
        } else {
            self.init()
        }
    }
    
    convenience init(twitterUser user: TwitterUser) {
        self.init()
        // badge
        platform = .twitter
        // avatar
        user.publisher(for: \.profileImageURL)
            .map { _ in user.avatarImageURL() }
            .assign(to: \.avatarImageURL, on: self)
            .store(in: &disposeBag)
        // name
        user.publisher(for: \.name)
            .map { $0 as String? }
            .assign(to: \.name, on: self)
            .store(in: &disposeBag)
        // username
        user.publisher(for: \.username)
            .map { "@" + $0 }
            .map { $0 as String? }
            .assign(to: \.username, on: self)
            .store(in: &disposeBag)
    }
    
    convenience init(mastodonUser user: MastodonUser) {
        self.init()
        // badge
        platform = .mastodon
        // avatar
        user.publisher(for: \.avatar)
            .map { avatar in avatar.flatMap { URL(string: $0) } }
            .assign(to: \.avatarImageURL, on: self)
            .store(in: &disposeBag)
        // name
        user.publisher(for: \.displayName)
            .map { _ in user.name as String? }
            .assign(to: \.name, on: self)
            .store(in: &disposeBag)
        // username
        user.publisher(for: \.acct)
            .map { _ in user.acctWithDomain }
            .map { $0 as String? }
            .assign(to: \.username, on: self)
            .store(in: &disposeBag)
    }
}
