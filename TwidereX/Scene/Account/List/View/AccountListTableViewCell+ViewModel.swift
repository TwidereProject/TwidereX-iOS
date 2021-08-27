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
    func configure(authenticationIndex: AuthenticationIndex) {
        if let twitterUser = authenticationIndex.twitterAuthentication?.twitterUser {
            configure(twitterUser: twitterUser)
        } else if let mastodonUser = authenticationIndex.mastodonAuthentication?.mastodonUser {
            configure(mastodonUser: mastodonUser)
        } else {
            assertionFailure()
        }
    }
    
    private func configure(twitterUser user: TwitterUser) {
        // badge
        userBriefInfoView.viewModel.platform = .twitter
        // avatar
        user.publisher(for: \.profileImageURL)
            .map { _ in user.avatarImageURL() }
            .assign(to: \.avatarImageURL, on: userBriefInfoView.viewModel)
            .store(in: &disposeBag)
        // name
        user.publisher(for: \.name)
            .map { $0 as String? }
            .assign(to: \.headlineText, on: userBriefInfoView.viewModel)
            .store(in: &disposeBag)
        // username
        user.publisher(for: \.username)
            .map { "@" + $0 }
            .map { $0 as String? }
            .assign(to: \.subheadlineText, on: userBriefInfoView.viewModel)
            .store(in: &disposeBag)
    }
    
    private func configure(mastodonUser user: MastodonUser) {
        // badge
        userBriefInfoView.viewModel.platform = .mastodon
        // avatar
        user.publisher(for: \.avatar)
            .map { avatar in avatar.flatMap { URL(string: $0) } }
            .assign(to: \.avatarImageURL, on: userBriefInfoView.viewModel)
            .store(in: &disposeBag)
        // name
        user.publisher(for: \.displayName)
            .map { _ in user.name as String? }
            .assign(to: \.headlineText, on: userBriefInfoView.viewModel)
            .store(in: &disposeBag)
        // username
        user.publisher(for: \.acct)
            .map { _ in user.acctWithDomain }
            .map { $0 as String? }
            .assign(to: \.subheadlineText, on: userBriefInfoView.viewModel)
            .store(in: &disposeBag)
    }
}
