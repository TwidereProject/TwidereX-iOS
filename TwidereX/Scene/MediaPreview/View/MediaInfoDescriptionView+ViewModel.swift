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
import AppShared
import CoreDataStack
import TwitterMeta
import MastodonMeta
import Meta

extension MediaInfoDescriptionView {
    final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        var observations = Set<NSKeyValueObservation>()
     
        @Published public var authorAvatarImageURL: URL?
        @Published public var authorName: MetaContent?
        
        @Published public var protected: Bool = false
        
        @Published public var content: MetaContent?
     
        @Published public var isRepost: Bool = false
        @Published public var isLike: Bool = false
    }
}

extension MediaInfoDescriptionView.ViewModel {
    func bind(view: MediaInfoDescriptionView) {
        // content
        $content
            .sink { metaContent in
                guard let content = metaContent else {
                    view.contentTextView.reset()
                    return
                }
                view.contentTextView.configure(content: content)
            }
            .store(in: &disposeBag)
        // avatar
        $authorAvatarImageURL
            .sink { url in
                let configuration = AvatarImageView.Configuration(url: url)
                view.avatarView.avatarButton.avatarImageView.configure(configuration: configuration)
            }
            .store(in: &disposeBag)
        UserDefaults.shared
            .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
                let avatarStyle = defaults.avatarStyle
                let animator = UIViewPropertyAnimator(duration: 0.3, timingParameters: UISpringTimingParameters())
                animator.addAnimations { [weak view] in
                    guard let view = view else { return }
                    switch avatarStyle {
                    case .circle:
                        view.avatarView.avatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .circle))
                    case .roundedSquare:
                        view.avatarView.avatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .scale(ratio: 4)))
                    }
                }
                animator.startAnimation()
            }
            .store(in: &observations)
        // name
        $authorName
            .sink { metaContent in
                let metaContent = metaContent ?? PlaintextMetaContent(string: "")
                view.nameMetaLabel.setupAttributes(style: StatusView.authorNameLabelStyle)
                view.nameMetaLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)
        // toolbar
        Publishers.CombineLatest(
            $isRepost,
            $protected
        )
        .sink { isRepost, protected in
            view.toolbar.setupRepost(count: 0, isRepost: isRepost, isLocked: protected)
        }
        .store(in: &disposeBag)
        $isLike
            .sink { isLike in
                view.toolbar.setupLike(count: 0, isLike: isLike)
            }
            .store(in: &disposeBag)
    }
}


extension MediaInfoDescriptionView {
    public struct ConfigurationContext {
        public let dateTimeProvider: DateTimeProvider
        public let twitterTextProvider: TwitterTextProvider
        public let activeAuthenticationContext: AnyPublisher<AuthenticationContext?, Never>
        
        public init(
            dateTimeProvider: DateTimeProvider,
            twitterTextProvider: TwitterTextProvider,
            activeAuthenticationContext: AnyPublisher<AuthenticationContext?, Never>
        ) {
            self.dateTimeProvider = dateTimeProvider
            self.twitterTextProvider = twitterTextProvider
            self.activeAuthenticationContext = activeAuthenticationContext
        }
    }
}


extension MediaInfoDescriptionView {
    public func configure(
        statusObject object: StatusObject,
        configurationContext: ConfigurationContext
    ) {
        switch object {
        case .twitter(let status):
            configure(
                twitterStatus: status,
                configurationContext: configurationContext
            )
        case .mastodon(let status):
            configure(
                mastodonStatus: status,
                configurationContext: configurationContext
            )
        }
    }
}

extension MediaInfoDescriptionView {
    public func configure(
        twitterStatus status: TwitterStatus,
        configurationContext: ConfigurationContext
    ) {
        configureAuthor(
            twitterStatus: status,
            dateTimeProvider: configurationContext.dateTimeProvider
        )
        configureContent(
            twitterStatus: status,
            twitterTextProvider: configurationContext.twitterTextProvider
        )
        configureToolbar(
            twitterStatus: status,
            activeAuthenticationContext: configurationContext.activeAuthenticationContext
        )
    }
    
    private func configureAuthor(
        twitterStatus status: TwitterStatus,
        dateTimeProvider: DateTimeProvider
    ) {
        let author = (status.repost ?? status).author
        
        // author avatar
        author.publisher(for: \.profileImageURL)
            .map { _ in author.avatarImageURL() }
            .assign(to: \.authorAvatarImageURL, on: viewModel)
            .store(in: &disposeBag)
        // lock
        author.publisher(for: \.protected)
            .assign(to: \.protected, on: viewModel)
            .store(in: &disposeBag)
        // author name
        author.publisher(for: \.name)
            .map { PlaintextMetaContent(string: $0) }
            .assign(to: \.authorName, on: viewModel)
            .store(in: &disposeBag)
    }
    
    private func configureContent(
        twitterStatus status: TwitterStatus,
        twitterTextProvider: TwitterTextProvider
    ) {
        let status = status.repost ?? status
        let content = TwitterContent(content: status.text)
        let metaContent = TwitterMetaContent.convert(
            content: content,
            urlMaximumLength: 20,
            twitterTextProvider: twitterTextProvider
        )
        viewModel.content = metaContent
    }
    
    private func configureToolbar(
        twitterStatus status: TwitterStatus,
        activeAuthenticationContext: AnyPublisher<AuthenticationContext?, Never>
    ) {
        let status = status.repost ?? status
        
        // relationship
        Publishers.CombineLatest(
            activeAuthenticationContext,
            status.publisher(for: \.repostBy)
        )
        .map { authenticationContext, repostBy in
            guard let authenticationContext = authenticationContext?.twitterAuthenticationContext else {
                return false
            }
            let userID = authenticationContext.userID
            return repostBy.contains(where: { $0.id == userID })
        }
        .assign(to: \.isRepost, on: viewModel)
        .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            activeAuthenticationContext,
            status.publisher(for: \.likeBy)
        )
        .map { authenticationContext, likeBy in
            guard let authenticationContext = authenticationContext?.twitterAuthenticationContext else {
                return false
            }
            let userID = authenticationContext.userID
            return likeBy.contains(where: { $0.id == userID })
        }
        .assign(to: \.isLike, on: viewModel)
        .store(in: &disposeBag)
    }
}

// MARK: - Mastodon
extension MediaInfoDescriptionView {
    public func configure(
        mastodonStatus status: MastodonStatus,
        configurationContext: ConfigurationContext
    ) {
//        configureHeader(mastodonStatus: status, mastodonNotification: notification)
        configureAuthor(mastodonStatus: status, dateTimeProvider: configurationContext.dateTimeProvider)
        configureContent(mastodonStatus: status)
//        configureMedia(mastodonStatus: status)
        configureToolbar(
            mastodonStatus: status,
            activeAuthenticationContext: configurationContext.activeAuthenticationContext
        )
    }
    
    private func configureAuthor(
        mastodonStatus status: MastodonStatus,
        dateTimeProvider: DateTimeProvider
    ) {
        let author = (status.repost ?? status).author
        
        // author avatar
        author.publisher(for: \.avatar)
            .map { url in url.flatMap { URL(string: $0) } }
            .assign(to: \.authorAvatarImageURL, on: viewModel)
            .store(in: &disposeBag)
        // author name
        Publishers.CombineLatest(
            author.publisher(for: \.displayName),
            author.publisher(for: \.emojis)
        )
        .map { _, emojis in
            let content = MastodonContent(content: author.name, emojis: emojis.asDictionary)
            do {
                let metaContent = try MastodonMetaContent.convert(document: content)
                return metaContent
            } catch {
                assertionFailure(error.localizedDescription)
                return PlaintextMetaContent(string: author.name)
            }
        }
        .assign(to: \.authorName, on: viewModel)
        .store(in: &disposeBag)
        // protected
        author.publisher(for: \.locked)
            .assign(to: \.protected, on: viewModel)
            .store(in: &disposeBag)

    }
    
    private func configureContent(mastodonStatus status: MastodonStatus) {
        let status = status.repost ?? status
        let content = MastodonContent(content: status.content, emojis: status.emojis.asDictionary)
        do {
            let metaContent = try MastodonMetaContent.convert(document: content)
            viewModel.content = metaContent
        } catch {
            assertionFailure(error.localizedDescription)
            viewModel.content = PlaintextMetaContent(string: "")
        }
    }
    
    private func configureToolbar(
        mastodonStatus status: MastodonStatus,
        activeAuthenticationContext: AnyPublisher<AuthenticationContext?, Never>
    ) {
        let status = status.repost ?? status
        
        // relationship
        Publishers.CombineLatest(
            activeAuthenticationContext,
            status.publisher(for: \.repostBy)
        )
            .map { authenticationContext, repostBy in
                guard let authenticationContext = authenticationContext?.mastodonAuthenticationContext else {
                    return false
                }
                let domain = authenticationContext.domain
                let userID = authenticationContext.userID
                return repostBy.contains(where: { $0.id == userID && $0.domain == domain })
            }
            .assign(to: \.isRepost, on: viewModel)
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            activeAuthenticationContext,
            status.publisher(for: \.likeBy)
        )
            .map { authenticationContext, likeBy in
                guard let authenticationContext = authenticationContext?.mastodonAuthenticationContext else {
                    return false
                }
                let domain = authenticationContext.domain
                let userID = authenticationContext.userID
                return likeBy.contains(where: { $0.id == userID && $0.domain == domain })
            }
            .assign(to: \.isLike, on: viewModel)
            .store(in: &disposeBag)
    }
}
