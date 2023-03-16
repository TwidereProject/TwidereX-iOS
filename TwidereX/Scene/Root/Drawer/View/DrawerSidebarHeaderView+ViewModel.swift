//
//  DrawerSidebarHeaderView+ViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-2.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import MetaTextKit
import CoreDataStack
import TwidereCore

extension DrawerSidebarHeaderView {
    class ViewModel: ObservableObject {
        var configureDisposeBag = Set<AnyCancellable>()
        var bindDisposeBag = Set<AnyCancellable>()
        
        @Published var avatarURL: URL?
        @Published var name: MetaContent?
        @Published var username: String?
        
        @Published var isProtected: Bool = false
        
        @Published var followingCount: Int?
        @Published var followersCount: Int?
        @Published var listedCount: Int?
        
        @Published var needsListCountDashboardMeterDisplay = true
    }
}

extension DrawerSidebarHeaderView.ViewModel {
    func bind(view: DrawerSidebarHeaderView) {
        // avatar
        $avatarURL
            .sink { avatarURL in
                let configuration = AvatarImageView.Configuration(url: avatarURL)
                view.avatarView.avatarButton.avatarImageView.configure(configuration: configuration)
            }
            .store(in: &bindDisposeBag)
        // name
        $name
            .receive(on: DispatchQueue.main)
            .sink { name in
                let metaContent = name ?? PlaintextMetaContent(string: "-")
                view.nameMetaLabel.configure(content: metaContent)
            }
            .store(in: &bindDisposeBag)
        // username
        $username
            .sink { username in
                let username = username.flatMap { "@" + $0 } ?? "-"
                view.usernameLabel.text = username
            }
            .store(in: &bindDisposeBag)
        // isProtected
        $isProtected
            .map { !$0 }
            .assign(to: \.isHidden, on: view.lockImageView)
            .store(in: &bindDisposeBag)
        // dashboard
        $followingCount
            .sink { count in
                if let count = count {
                    view.profileDashboardView.followingMeterView.countLabel.text = "\(count)"
                } else {
                    view.profileDashboardView.followingMeterView.countLabel.text = "-"
                }
            }
            .store(in: &bindDisposeBag)
        $followersCount
            .sink { count in
                if let count = count {
                    view.profileDashboardView.followerMeterView.countLabel.text = "\(count)"
                } else {
                    view.profileDashboardView.followerMeterView.countLabel.text = "-"
                }
            }
            .store(in: &bindDisposeBag)
        $listedCount
            .sink { count in
                if let count = count {
                    view.profileDashboardView.listedMeterView.countLabel.text = "\(count)"
                } else {
                    view.profileDashboardView.listedMeterView.countLabel.text = "-"
                }
            }
            .store(in: &bindDisposeBag)
        $needsListCountDashboardMeterDisplay
            .sink { needsListCountDashboardMeterDisplay in
                view.profileDashboardView.listedMeterView.isHidden = !needsListCountDashboardMeterDisplay
                view.profileDashboardView.separatorLine2.isHidden = !needsListCountDashboardMeterDisplay
            }
            .store(in: &bindDisposeBag)
    }
}

extension DrawerSidebarHeaderView {
    func configure(user: UserObject?) {
        // reset
        viewModel.configureDisposeBag.removeAll()
        
        guard let user = user else {
            reset()
            return
        }
        
        switch user {
        case .twitter(let object):
            configure(twitterUser: object)
        case .mastodon(let object):
            configure(mastodonUser: object)
        }
    }

    private func reset() {
        viewModel.avatarURL = nil
        viewModel.name = nil
        viewModel.username = nil
        viewModel.isProtected = false
        viewModel.followingCount = nil
        viewModel.followersCount = nil
        viewModel.listedCount = nil
        viewModel.needsListCountDashboardMeterDisplay = true
    }
}

extension DrawerSidebarHeaderView {
    func configure(twitterUser user: TwitterUser) {
        // avatar
        user.publisher(for: \.profileImageURL)
            .map { _ in user.avatarImageURL() }
            .assign(to: \.avatarURL, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // name
        user.publisher(for: \.name)
            .map { name in PlaintextMetaContent(string: name) }
            .assign(to: \.name, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // username
        user.publisher(for: \.username)
            .map { $0 as String? }
            .assign(to: \.username, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // isProtected
        user.publisher(for: \.protected)
            .assign(to: \.isProtected, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // dashboard
        user.publisher(for: \.followingCount)
            .map { Int($0) }
            .assign(to: \.followingCount, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        user.publisher(for: \.followersCount)
            .map { Int($0) }
            .assign(to: \.followersCount, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        user.publisher(for: \.listedCount)
            .map { Int($0) }
            .assign(to: \.listedCount, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        viewModel.needsListCountDashboardMeterDisplay = true
    }
}

extension DrawerSidebarHeaderView {
    func configure(mastodonUser user: MastodonUser) {
        // avatar
        user.publisher(for: \.avatar)
            .map { avatar in avatar.flatMap { URL(string: $0) } }
            .assign(to: \.avatarURL, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // name
        user.publisher(for: \.displayName)
            .map { _ in user.nameMetaContent }
            .assign(to: \.name, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // username
        user.publisher(for: \.username)
            .map { $0 as String? }
            .assign(to: \.username, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // isProtected
        user.publisher(for: \.locked)
            .assign(to: \.isProtected, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // dashboard
        user.publisher(for: \.followingCount)
            .map { Int($0) }
            .assign(to: \.followingCount, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        user.publisher(for: \.followersCount)
            .map { Int($0) }
            .assign(to: \.followersCount, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        viewModel.needsListCountDashboardMeterDisplay = false
    }
}
