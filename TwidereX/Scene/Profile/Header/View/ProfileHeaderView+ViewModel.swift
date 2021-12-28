//
//  ProfileHeaderView+ViewModel.swift
//  ProfileHeaderView+ViewModel
//
//  Created by Cirno MainasuK on 2021-9-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreDataStack
import TwitterMeta
import MastodonMeta
import AlamofireImage
import AppShared
import TwidereCore

extension ProfileHeaderView {
    class ViewModel: ObservableObject {
        var configureDisposeBag = Set<AnyCancellable>()
        var bindDisposeBag = Set<AnyCancellable>()
        
        static let joinDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            return formatter
        }()
        
        @Published var bannerImageURL: URL?
        @Published var avatarImageURL: URL?
                
        @Published var isBot: Bool = false
        @Published var isVerified: Bool = false
        @Published var isProtected: Bool = false
        
        @Published var name: MetaContent = PlaintextMetaContent(string: "")
        @Published var username: String = ""
        
        @Published var isFollowsYou: Bool = false
        @Published var relationship: Relationship?
        
        @Published var bioMetaContent: MetaContent?
        @Published var fields: [ProfileFieldListView.Item]?
        
        @Published var followingCount: Int?
        @Published var followersCount: Int?
        @Published var listedCount: Int?
        
        @Published var needsListCountDashboardMeterDisplay = true
    }
}

extension ProfileHeaderView.ViewModel {
    func bind(profileHeaderView: ProfileHeaderView) {
        // banner
        $bannerImageURL
            .sink { imageURL in
                profileHeaderView.bannerImageView.af.cancelImageRequest()
                
                let placeholder = UIImage.placeholder(color: .systemFill)
                guard let imageURL = imageURL else {
                    profileHeaderView.bannerImageView.image = placeholder
                    return
                }
                profileHeaderView.bannerImageView.af.setImage(
                    withURL: imageURL,
                    placeholderImage: placeholder,
                    imageTransition: .crossDissolve(0.2)
                )
            }
            .store(in: &bindDisposeBag)
        // avatar
        $avatarImageURL
            .removeDuplicates()
            .sink { imageURL in
                profileHeaderView.avatarView.avatarButton.avatarImageView.setImage(
                    url: imageURL,
                    placeholder: .placeholder(color: .systemFill),
                    scaleToSize: nil
                )
            }
            .store(in: &bindDisposeBag)
        // badge
        Publishers.CombineLatest(
            $isBot,
            $isVerified
        )
        .sink { isBot, isVerified in
            if isVerified {
                profileHeaderView.avatarView.badge = .verified
            } else {
                profileHeaderView.avatarView.badge = .none
            }
        }
        .store(in: &bindDisposeBag)
        // isFollowsYou
        $isFollowsYou
            .map { !$0 }
            .assign(to: \.isHidden, on: profileHeaderView.followsYouIndicatorLabel)
            .store(in: &bindDisposeBag)
        // isProtected
        $isProtected
            .map { !$0 }
            .assign(to: \.isHidden, on: profileHeaderView.protectLockImageViewContainer)
            .store(in: &bindDisposeBag)
        // name
        $name
            .sink { content in
                profileHeaderView.nameLabel.setupAttributes(style: .profileAuthorName)
                profileHeaderView.nameLabel.configure(content: content)
                profileHeaderView._placeholderNameLabel.setupAttributes(style: .profileAuthorName)
                profileHeaderView._placeholderNameLabel.configure(content: PlaintextMetaContent(string: " "))
            }
            .store(in: &bindDisposeBag)
        // username
        $username
            .sink { username in
                let metaContent = PlaintextMetaContent(string: "@" + username)
                profileHeaderView.usernameLabel.setupAttributes(style: .profileAuthorUsername)
                profileHeaderView.usernameLabel.configure(content: metaContent)
            }
            .store(in: &bindDisposeBag)
        $relationship
            .sink { relationship in
                guard let relationship = relationship else { return }
                profileHeaderView.friendshipButton.configure(relationship: relationship)
                profileHeaderView.friendshipButton.isHidden = relationship == .isMyself
            }
            .store(in: &bindDisposeBag)
        // bio
        $bioMetaContent
            .sink { metaContent in
                profileHeaderView.isHidden = metaContent == nil
                guard let metaContent = metaContent else {
                    profileHeaderView.bioTextAreaView.reset()
                    return
                }
                profileHeaderView.bioTextAreaView.setupAttributes(style: .profileAuthorBio)
                profileHeaderView.bioTextAreaView.configure(content: metaContent)
            }
            .store(in: &bindDisposeBag)
        // fields
        $fields
            .sink { fields in
                profileHeaderView.fieldListView.isHidden = fields == nil
                guard let fields = fields else {
                    return
                }
                profileHeaderView.fieldListView.configure(items: fields)
            }
            .store(in: &bindDisposeBag)
        // dashboard
        $followingCount
            .sink { count in
                if let count = count {
                    profileHeaderView.dashboardView.followingMeterView.countLabel.text = "\(count)"
                } else {
                    profileHeaderView.dashboardView.followingMeterView.countLabel.text = "-"
                }
            }
            .store(in: &bindDisposeBag)
        $followersCount
            .sink { count in
                if let count = count {
                    profileHeaderView.dashboardView.followerMeterView.countLabel.text = "\(count)"
                } else {
                    profileHeaderView.dashboardView.followerMeterView.countLabel.text = "-"
                }
            }
            .store(in: &bindDisposeBag)
        $listedCount
            .sink { count in
                if let count = count {
                    profileHeaderView.dashboardView.listedMeterView.countLabel.text = "\(count)"
                } else {
                    profileHeaderView.dashboardView.listedMeterView.countLabel.text = "-"
                }
            }
            .store(in: &bindDisposeBag)
        $needsListCountDashboardMeterDisplay
            .sink { needsListCountDashboardMeterDisplay in
                profileHeaderView.dashboardView.listedMeterView.isHidden = !needsListCountDashboardMeterDisplay
                profileHeaderView.dashboardView.separatorLine2.isHidden = !needsListCountDashboardMeterDisplay
            }
            .store(in: &bindDisposeBag)
    }
}

extension ProfileHeaderView {
    func configure(user: UserObject?) {
        // reset
        viewModel.configureDisposeBag.removeAll()
        
        guard let user = user else { return }
        
        switch user {
        case .twitter(let object):
            configure(twitterUser: object)
        case .mastodon(let object):
            configure(mastodonUser: object)
        }
    }
    
    func configure(relationshipOptionSet optionSet: RelationshipOptionSet?) {
        viewModel.relationship = optionSet?.relationship(except: [.muting])
        viewModel.isFollowsYou = optionSet?.contains(.followingBy) ?? false
    }
}

// MARK: - Twitter
extension ProfileHeaderView {
    private func configure(twitterUser user: TwitterUser) {
        // banner
        user.publisher(for: \.profileBannerURL)
            .map { string in string.flatMap { URL(string: $0) } }
            .assign(to: \.bannerImageURL, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // avatar
        user.publisher(for: \.profileImageURL)
            .map { _ in user.avatarImageURL(size: .original) }
            .assign(to: \.avatarImageURL, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // isVerified
        user.publisher(for: \.verified)
            .assign(to: \.isVerified, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // isProtected
        user.publisher(for: \.protected)
            .assign(to: \.isProtected, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // name
        user.publisher(for: \.name)
            .combineLatest(UIContentSizeCategory.publisher) { value, _ in
                Meta.convert(from: .plaintext(string: value))
            }
            .assign(to: \.name, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // username
        user.publisher(for: \.username)
            .combineLatest(UIContentSizeCategory.publisher) { value, _ in value }
            .assign(to: \.username, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // content
        configureContent(twitterUser: user)
        // field
        configureField(twitterUser: user)
        // dashboard
        user.publisher(for: \.followingCount)
            .combineLatest(UIContentSizeCategory.publisher) { value, _ in value }
            .map { Int($0) }
            .assign(to: \.followingCount, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        user.publisher(for: \.followersCount)
            .combineLatest(UIContentSizeCategory.publisher) { value, _ in value }
            .map { Int($0) }
            .assign(to: \.followersCount, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        user.publisher(for: \.listedCount)
            .combineLatest(UIContentSizeCategory.publisher) { value, _ in value }
            .map { Int($0) }
            .assign(to: \.listedCount, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        viewModel.needsListCountDashboardMeterDisplay = true
    }
    
    private func configureContent(twitterUser user: TwitterUser) {
        Publishers.CombineLatest3(
            user.publisher(for: \.bio),
            user.publisher(for: \.bioEntities),
            UIContentSizeCategory.publisher
        )
        .map { _, _, _ in user.bioMetaContent(provider: OfficialTwitterTextProvider()) }
        .assign(to: \.bioMetaContent, on: viewModel)
        .store(in: &viewModel.configureDisposeBag)
    }
    
    private func configureField(twitterUser user: TwitterUser) {
        Publishers.CombineLatest3(
            user.publisher(for: \.url),
            user.publisher(for: \.location),
            UIContentSizeCategory.publisher
        )
        .map { _, _, _ -> [ProfileFieldListView.Item]? in
            var fields: [ProfileFieldListView.Item] = []
            var index = 0
            let now = Date()
            if let value = user.urlMetaContent(provider: OfficialTwitterTextProvider()) {
                let item = ProfileFieldListView.Item(
                    index: index,
                    updateAt: now,
                    symbol: Asset.ObjectTools.globeMini.image,
                    key: nil,
                    value: value
                )
                fields.append(item)
                index += 1
            }
            if let value = user.locationMetaContent(provider: OfficialTwitterTextProvider()) {
                let item = ProfileFieldListView.Item(
                    index: index,
                    updateAt: now,
                    symbol: Asset.ObjectTools.mappinMini.image,
                    key: nil,
                    value: value
                )
                fields.append(item)
                index += 1
            }
            if let createdAt = user.createdAt {
                let value: PlaintextMetaContent = {
                    let dateString = ProfileHeaderView.ViewModel.joinDateFormatter.string(from: createdAt)
                    let string = L10n.Scene.Profile.Fields.joinedInDate(dateString)
                    return PlaintextMetaContent(string: string)
                }()
                let item = ProfileFieldListView.Item(
                    index: index,
                    updateAt: now,
                    symbol: Asset.ObjectTools.seedingMini.image,
                    key: nil,
                    value: value
                )
                fields.append(item)
                index += 1
            }
            guard !fields.isEmpty else { return nil }
            return fields
        }
        .assign(to: \.fields, on: viewModel)
        .store(in: &viewModel.configureDisposeBag)
    }
}

// MARK: - Mastodon
extension ProfileHeaderView {
    private func configure(mastodonUser user: MastodonUser) {
        // banner
        user.publisher(for: \.header)
            .map { string in string.flatMap { URL(string: $0) } }
            .assign(to: \.bannerImageURL, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // avatar
        user.publisher(for: \.avatar)
            .map { string in string.flatMap { URL(string: $0) } }
            .assign(to: \.avatarImageURL, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // isProtected
        user.publisher(for: \.locked)
            .assign(to: \.isProtected, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // name
        Publishers.CombineLatest3(
            user.publisher(for: \.displayName),
            user.publisher(for: \.emojis),
            UIContentSizeCategory.publisher
        )
        .map { _, emojis, _ -> MetaContent in
            Meta.convert(from: .mastodon(string: user.name, emojis: emojis.asDictionary))
        }
        .assign(to: \.name, on: viewModel)
        .store(in: &viewModel.configureDisposeBag)
        // username
        user.publisher(for: \.acct)
            .combineLatest(UIContentSizeCategory.publisher) { _, _ in user.acctWithDomain }
            .assign(to: \.username, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
        // content
        configureContent(mastodonUser: user)
        // field
        configureField(mastodonUser: user)
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
    
    private func configureContent(mastodonUser user: MastodonUser) {
        Publishers.CombineLatest3(
            user.publisher(for: \.note),
            user.publisher(for: \.emojis),
            UIContentSizeCategory.publisher
        )
        .map { _, _, _ in user.bioMetaContent }
        .assign(to: \.bioMetaContent, on: viewModel)
        .store(in: &viewModel.configureDisposeBag)
    }
    
    private func configureField(mastodonUser user: MastodonUser) {
        Publishers.CombineLatest3(
            user.publisher(for: \.fields),
            user.publisher(for: \.emojis),
            UIContentSizeCategory.publisher
        )
        .map { fields, emojis, _ -> [ProfileFieldListView.Item]? in
            guard !fields.isEmpty else { return nil }
            let now = Date()
            
            let emojis = emojis.asDictionary
            let items = fields.enumerated().map { i, field -> ProfileFieldListView.Item in
                let key = Meta.convert(
                    from: .mastodon(string: field.name, emojis: emojis)
                )
                let value = Meta.convert(
                    from: .mastodon(string: field.value, emojis: emojis)
                )
                return ProfileFieldListView.Item(
                    index: i,
                    updateAt: now,
                    symbol: nil,
                    key: key,
                    value: value
                )
            }
            return items
        }
        .assign(to: \.fields, on: viewModel)
        .store(in: &viewModel.configureDisposeBag)
    }
}
