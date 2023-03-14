//
//  MediaInfoDescriptionView+ViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-7.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import AppShared
import TwidereCore
import TwitterMeta
import MastodonMeta
import Meta

extension MediaInfoDescriptionView {
    final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        var observations = Set<NSKeyValueObservation>()
        
        @Published public var platform: Platform = .none
        @Published public var twitterTextProvider: TwitterTextProvider?
        @Published public var dateTimeProvider: DateTimeProvider?
        @Published public var authenticationContext: AuthenticationContext?
     
        @Published public var authorUserIdentifier: UserIdentifier?
        @Published public var authorAvatarImageURL: URL?
        @Published public var authorName: MetaContent?
        
        @Published public var protected = false
        @Published public var isMyself = false
        
        @Published public var content: MetaContent?

        @Published public var visibility: MastodonVisibility?
     
        @Published public var isRepost = false
        @Published public var isRepostEnabled = true
        
        @Published public var isLike = false
        
        init() {
            // isMyself
            Publishers.CombineLatest(
                $authenticationContext,
                $authorUserIdentifier
            )
            .map { authenticationContext, authorUserIdentifier -> Bool in
                guard let authenticationContext = authenticationContext,
                      let authorUserIdentifier = authorUserIdentifier
                else { return false }
                let meUserIdentifier = authenticationContext.userIdentifier
                switch (meUserIdentifier, authorUserIdentifier) {
                case (.twitter(let me), .twitter(let author)):
                    return me.id == author.id
                case (.mastodon(let me), .mastodon(let author)):
                    return me.domain == author.domain
                        && me.id == author.id
                default:
                    return false
                }
            }
            .assign(to: &$isMyself)
            // isRepostEnabled
            Publishers.CombineLatest4(
                $platform,
                $protected,
                $isMyself,
                $visibility
            )
            .map { platform, protected, isMyself, visibility -> Bool in
                switch platform {
                case .none:
                    return true
                case .twitter:
                    guard !isMyself else { return true }
                    return !protected
                case .mastodon:
                    guard !isMyself else { return true }
                    guard let visibility = visibility else {
                        return true
                    }
                    switch visibility {
                    case .public, .unlisted:
                        return true
                    case .private, .direct, ._other:
                        return false
                    }
                }
            }
            .assign(to: &$isRepostEnabled)
        }
    }
}

extension MediaInfoDescriptionView.ViewModel {
    func bind(view: MediaInfoDescriptionView) {
//        // avatar
//        $authorAvatarImageURL
//            .sink { url in
//                let configuration = AvatarImageView.Configuration(url: url)
//                view.avatarView.avatarButton.avatarImageView.configure(configuration: configuration)
//            }
//            .store(in: &disposeBag)
//        UserDefaults.shared
//            .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
//                let avatarStyle = defaults.avatarStyle
//                let animator = UIViewPropertyAnimator(duration: 0.3, timingParameters: UISpringTimingParameters())
//                animator.addAnimations { [weak view] in
//                    guard let view = view else { return }
//                    switch avatarStyle {
//                    case .circle:
//                        view.avatarView.avatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .circle))
//                    case .roundedSquare:
//                        view.avatarView.avatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .scale(ratio: 4)))
//                    }
//                }
//                animator.startAnimation()
//            }
//            .store(in: &observations)
//        // name
//        $authorName
//            .sink { metaContent in
//                let metaContent = metaContent ?? PlaintextMetaContent(string: "")
//                view.nameMetaLabel.setupAttributes(style: StatusView.authorNameLabelStyle)
//                view.nameMetaLabel.configure(content: metaContent)
//            }
//            .store(in: &disposeBag)
//        // content
//        $content
//            .sink { metaContent in
//                guard let content = metaContent else {
//                    view.contentTextView.reset()
//                    return
//                }
//                view.contentTextView.configure(content: content)
//            }
//            .store(in: &disposeBag)
//        // toolbar
//        $platform
//            .assign(to: \.platform, on: view.toolbar.viewModel)
//            .store(in: &disposeBag)
//        Publishers.CombineLatest(
//            $isRepost,
//            $isRepostEnabled
//        )
//        .sink { isRepost, isEnabled in
//            view.toolbar.setupRepost(count: 0, isEnabled: isEnabled, isHighlighted: isRepost)
//        }
//        .store(in: &disposeBag)
//        $isLike
//            .sink { isLike in
//                 view.toolbar.setupLike(count: 0, isHighlighted: isLike)
//            }
//            .store(in: &disposeBag)
    }
}

extension MediaInfoDescriptionView {
    public func configure(
        statusObject object: StatusObject
        // configurationContext: ConfigurationContext
    ) {
//        switch object {
//        case .twitter(let status):
//            configure(
//                twitterStatus: status,
//                configurationContext: configurationContext
//            )
//        case .mastodon(let status):
//            configure(
//                mastodonStatus: status,
//                configurationContext: configurationContext
//            )
//        }
    }
}

extension MediaInfoDescriptionView {
//    public func configure(
//        twitterStatus status: TwitterStatus,
//        configurationContext: ConfigurationContext
//    ) {
//        viewModel.platform = .twitter
//        viewModel.dateTimeProvider = configurationContext.dateTimeProvider
//        viewModel.twitterTextProvider = configurationContext.twitterTextProvider
//
//        configureAuthor(twitterStatus: status)
//        configureContent(twitterStatus: status)
//        configureToolbar(twitterStatus: status)
//    }
//
//    private func configureAuthor(twitterStatus status: TwitterStatus) {
//        let author = (status.repost ?? status).author
//
//        // author avatar
//        author.publisher(for: \.profileImageURL)
//            .map { _ in author.avatarImageURL() }
//            .assign(to: \.authorAvatarImageURL, on: viewModel)
//            .store(in: &disposeBag)
//        // lock
//        author.publisher(for: \.protected)
//            .assign(to: \.protected, on: viewModel)
//            .store(in: &disposeBag)
//        // author name
//        author.publisher(for: \.name)
//            .map { PlaintextMetaContent(string: $0) }
//            .assign(to: \.authorName, on: viewModel)
//            .store(in: &disposeBag)
//    }
//
//    private func configureContent(twitterStatus status: TwitterStatus) {
//        guard let twitterTextProvider = viewModel.twitterTextProvider else {
//            assertionFailure()
//            return
//        }
//
//        let status = status.repost ?? status
//        let content = TwitterContent(content: status.text)
//        let metaContent = TwitterMetaContent.convert(
//            content: content,
//            urlMaximumLength: 20,
//            twitterTextProvider: twitterTextProvider
//        )
//        viewModel.content = metaContent
//        viewModel.visibility = nil
//    }
//
//    private func configureToolbar(twitterStatus status: TwitterStatus) {
//        let status = status.repost ?? status
//
//        // relationship
//        Publishers.CombineLatest(
//            viewModel.$authenticationContext,
//            status.publisher(for: \.repostBy)
//        )
//        .map { authenticationContext, repostBy in
//            guard let authenticationContext = authenticationContext?.twitterAuthenticationContext else {
//                return false
//            }
//            let userID = authenticationContext.userID
//            return repostBy.contains(where: { $0.id == userID })
//        }
//        .assign(to: \.isRepost, on: viewModel)
//        .store(in: &disposeBag)
//
//        Publishers.CombineLatest(
//            viewModel.$authenticationContext,
//            status.publisher(for: \.likeBy)
//        )
//        .map { authenticationContext, likeBy in
//            guard let authenticationContext = authenticationContext?.twitterAuthenticationContext else {
//                return false
//            }
//            let userID = authenticationContext.userID
//            return likeBy.contains(where: { $0.id == userID })
//        }
//        .assign(to: \.isLike, on: viewModel)
//        .store(in: &disposeBag)
//    }
}

// MARK: - Mastodon
extension MediaInfoDescriptionView {
//    public func configure(
//        mastodonStatus status: MastodonStatus,
//        configurationContext: ConfigurationContext
//    ) {
//        viewModel.platform = .mastodon
//        viewModel.dateTimeProvider = configurationContext.dateTimeProvider
//        viewModel.twitterTextProvider = configurationContext.twitterTextProvider
//
////        configureHeader(mastodonStatus: status, mastodonNotification: notification)
//        configureAuthor(mastodonStatus: status)
//        configureContent(mastodonStatus: status)
////        configureMedia(mastodonStatus: status)
//        configureToolbar(mastodonStatus: status)
//    }
    
//    private func configureAuthor(mastodonStatus status: MastodonStatus) {
//        let author = (status.repost ?? status).author
//        
//        // author avatar
//        author.publisher(for: \.avatar)
//            .map { url in url.flatMap { URL(string: $0) } }
//            .assign(to: \.authorAvatarImageURL, on: viewModel)
//            .store(in: &disposeBag)
//        // author name
//        Publishers.CombineLatest(
//            author.publisher(for: \.displayName),
//            author.publisher(for: \.emojis)
//        )
//        .map { _, emojis in
//            let content = MastodonContent(content: author.name, emojis: emojis.asDictionary)
//            do {
//                let metaContent = try MastodonMetaContent.convert(document: content)
//                return metaContent
//            } catch {
//                assertionFailure(error.localizedDescription)
//                return PlaintextMetaContent(string: author.name)
//            }
//        }
//        .assign(to: \.authorName, on: viewModel)
//        .store(in: &disposeBag)
//        // protected
//        author.publisher(for: \.locked)
//            .assign(to: \.protected, on: viewModel)
//            .store(in: &disposeBag)
//
//    }
//    
//    private func configureContent(mastodonStatus status: MastodonStatus) {
//        let status = status.repost ?? status
//        let content = MastodonContent(content: status.content, emojis: status.emojis.asDictionary)
//        do {
//            let metaContent = try MastodonMetaContent.convert(document: content)
//            viewModel.content = metaContent
//        } catch {
//            assertionFailure(error.localizedDescription)
//            viewModel.content = PlaintextMetaContent(string: "")
//        }
//        
//        viewModel.visibility = status.visibility
//    }
//    
//    private func configureToolbar(mastodonStatus status: MastodonStatus) {
//        let status = status.repost ?? status
//        
//        // relationship
//        Publishers.CombineLatest(
//            viewModel.$authenticationContext,
//            status.publisher(for: \.repostBy)
//        )
//            .map { authenticationContext, repostBy in
//                guard let authenticationContext = authenticationContext?.mastodonAuthenticationContext else {
//                    return false
//                }
//                let domain = authenticationContext.domain
//                let userID = authenticationContext.userID
//                return repostBy.contains(where: { $0.id == userID && $0.domain == domain })
//            }
//            .assign(to: \.isRepost, on: viewModel)
//            .store(in: &disposeBag)
//        
//        Publishers.CombineLatest(
//            viewModel.$authenticationContext,
//            status.publisher(for: \.likeBy)
//        )
//            .map { authenticationContext, likeBy in
//                guard let authenticationContext = authenticationContext?.mastodonAuthenticationContext else {
//                    return false
//                }
//                let domain = authenticationContext.domain
//                let userID = authenticationContext.userID
//                return likeBy.contains(where: { $0.id == userID && $0.domain == domain })
//            }
//            .assign(to: \.isLike, on: viewModel)
//            .store(in: &disposeBag)
//    }
}
