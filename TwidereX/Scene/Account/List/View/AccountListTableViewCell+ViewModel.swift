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
import MastodonMeta

extension AccountListTableViewCell {
    func configure(authenticationIndex: AuthenticationIndex) {
        if let twitterUser = authenticationIndex.twitterAuthentication?.user {
            configure(twitterUser: twitterUser)
        } else if let mastodonUser = authenticationIndex.mastodonAuthentication?.user {
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
            .map { PlaintextMetaContent(string: $0) }
            .assign(to: \.headlineMetaContent, on: userBriefInfoView.viewModel)
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
        Publishers.CombineLatest(
            user.publisher(for: \.displayName),
            user.publisher(for: \.emojis)
        )
        .map { _, emojis -> MetaContent? in
            let content = MastodonContent(content: user.name, emojis: emojis.asDictionary)
            do {
                let metaContent = try MastodonMetaContent.convert(document: content)
                return metaContent
            } catch {
                assertionFailure()
                return PlaintextMetaContent(string: user.name)
            }
        }
        .assign(to: \.headlineMetaContent, on: userBriefInfoView.viewModel)
        .store(in: &disposeBag)
        // username
        user.publisher(for: \.acct)
            .map { _ in user.acctWithDomain }
            .map { $0 as String? }
            .assign(to: \.subheadlineText, on: userBriefInfoView.viewModel)
            .store(in: &disposeBag)
    }
}
