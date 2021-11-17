//
//  StatusView+ViewModel.swift
//  StatusView+ViewModel
//
//  Created by Cirno MainasuK on 2021-8-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import SwiftUI
import CoreData
import CoreDataStack
import TwitterMeta
import MastodonMeta
import Meta

extension StatusView {
    final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        var objects = Set<NSManagedObject>()
        
        @Published var platform: Platform = .none
        
        @Published var header: Header = .none
        
        @Published var authorAvatarImageURL: URL?
        @Published var authorName: MetaContent?
        @Published var authorUsername: String?
        
        @Published var content: MetaContent?
        @Published var mediaViewConfigurations: [MediaView.Configuration] = []
        @Published var location: String?
        
        @Published var isRepost: Bool = false
        @Published var isLike: Bool = false
        
        @Published var replyCount: Int = 0
        @Published var repostCount: Int = 0
        @Published var likeCount: Int = 0
        
        @Published var timestamp: Date?
        
        enum Header {
            case none
            case repost(info: RepostInfo)
            case notification(info: NotificationHeaderInfo)
            // TODO: replyTo
            
            struct RepostInfo {
                let authorNameMetaContent: MetaContent
            }
        }
    }
}

extension StatusView.ViewModel {
    func bind(statusView: StatusView) {
        bindHeader(statusView: statusView)
        bindAuthor(statusView: statusView)
        bindContent(statusView: statusView)
        bindMedia(statusView: statusView)
        bindLocation(statusView: statusView)
        bindToolbar(statusView: statusView)
    }
    
    private func bindHeader(statusView: StatusView) {
        $header
            .sink { header in
                switch header {
                case .none:
                    return
                case .repost(let info):
                    statusView.headerIconImageView.image = Asset.Media.repeat.image
                    statusView.headerIconImageView.tintColor = Asset.Colors.Theme.daylight.color
                    statusView.headerTextLabel.setupAttributes(style: StatusView.headerTextLabelStyle)
                    statusView.headerTextLabel.configure(content: info.authorNameMetaContent)
                    statusView.setHeaderDisplay()
                case .notification(let info):
                    statusView.headerIconImageView.image = info.iconImage
                    statusView.headerIconImageView.tintColor = info.iconImageTintColor
                    statusView.headerTextLabel.setupAttributes(style: StatusView.headerTextLabelStyle)
                    statusView.headerTextLabel.configure(content: info.textMetaContent)
                    statusView.setHeaderDisplay()
                }
            }
            .store(in: &disposeBag)
    }
    
    private func bindAuthor(statusView: StatusView) {
        // avatar
        $authorAvatarImageURL
            .sink { url in
                let configuration = AvatarImageView.Configuration(url: url)
                statusView.authorAvatarButton.avatarImageView.configure(configuration: configuration)
            }
            .store(in: &disposeBag)
        // name
        $authorName
            .sink { metaContent in
                let metaContent = metaContent ?? PlaintextMetaContent(string: "")
                statusView.authorNameLabel.setupAttributes(style: StatusView.authorNameLabelStyle)
                statusView.authorNameLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)
        // username
        $authorUsername
            .map { text in
                guard let text = text else { return "" }
                return "@\(text)"
            }
            .assign(to: \.text, on: statusView.authorUsernameLabel)
            .store(in: &disposeBag)
        // timestamp
        $timestamp
            .sink { timestamp in
                statusView.timestampLabel.text = timestamp?.shortTimeAgoSinceNow
            }
            .store(in: &disposeBag)
    }
    
    private func bindContent(statusView: StatusView) {
        $content
            .sink { metaContent in
                guard let content = metaContent else {
                    statusView.contentTextView.reset()
                    return
                }
                statusView.contentTextView.configure(content: content)
            }
            .store(in: &disposeBag)
    }
    
    private func bindMedia(statusView: StatusView) {
        $mediaViewConfigurations
            .sink { configurations in
                let maxSize = CGSize(
                    width: statusView.contentMaxLayoutWidth,
                    height: statusView.contentMaxLayoutWidth
                )
                var needsDisplay = true
                switch configurations.count {
                case 0:
                    needsDisplay = false
                case 1:
                    let configuration = configurations[0]
                    let adaptiveLayout = MediaGridContainerView.AdaptiveLayout(
                        aspectRatio: configuration.aspectRadio,
                        maxSize: maxSize
                    )
                    let mediaView = statusView.mediaGridContainerView.dequeueMediaView(adaptiveLayout: adaptiveLayout)
                    mediaView.setup(configuration: configuration)
                default:
                    let gridLayout = MediaGridContainerView.GridLayout(
                        count: configurations.count,
                        maxSize: maxSize
                    )
                    let mediaViews = statusView.mediaGridContainerView.dequeueMediaView(gridLayout: gridLayout)
                    for (i, (configuration, mediaView)) in zip(configurations, mediaViews).enumerated() {
                        guard i < MediaGridContainerView.maxCount else { break }
                        mediaView.setup(configuration: configuration)
                    }
                }
                if needsDisplay {
                    statusView.setMediaDisplay()
                }
            }
            .store(in: &disposeBag)
    }
    
    private func bindLocation(statusView: StatusView) {
        $location
            .sink { location in
                guard let location = location, !location.isEmpty else { return }
                if statusView.traitCollection.preferredContentSizeCategory > .extraLarge {
                    statusView.locationMapPinImageView.image = Asset.ObjectTools.mappin.image
                } else {
                    statusView.locationMapPinImageView.image = Asset.ObjectTools.mappinMini.image
                }
                statusView.locationLabel.text = location
                statusView.setLocationDisplay()
            }
            .store(in: &disposeBag)
    }
    
    private func bindToolbar(statusView: StatusView) {
        $replyCount
            .sink { count in
                statusView.toolbar.setupReply(count: count, isEnabled: true)
            }
            .store(in: &disposeBag)
        Publishers.CombineLatest(
            $isRepost,
            $repostCount
        )
        .sink { isRepost, count in
            statusView.toolbar.setupRepost(count: count, isRepost: isRepost, isLocked: false)
        }
        .store(in: &disposeBag)
        Publishers.CombineLatest(
            $isLike,
            $likeCount
        )
        .sink { isLike, count in
            statusView.toolbar.setupLike(count: count, isLike: isLike)
        }
        .store(in: &disposeBag)
    }
}

extension StatusView {
    func configure(feed: Feed) {
        switch feed.content {
        case .none:
            assertionFailure()
        case .twitter(let status):
            configure(twitterStatus: status)
        case .mastodon(let status):
            configure(mastodonStatus: status, notification: nil)
        case .mastodonNotification(let notification):
            guard let status = notification.status else {
                assertionFailure()
                return
            }
            configure(mastodonStatus: status, notification: notification)
        }
    }
}

// MARK: - Twitter

extension StatusView {
    func configure(twitterStatus status: TwitterStatus) {
        viewModel.objects.insert(status)
        
        configureHeader(twitterStatus: status)
        configureAuthor(twitterStatus: status)
        configureContent(twitterStatus: status)
        configureMedia(twitterStatus: status)
        configureLocation(twitterStatus: status)
        configureToolbar(twitterStatus: status)
        
        if let quote = status.quote {
            quoteStatusView?.configure(twitterStatus: quote)
            setQuoteDisplay()
        }
    }
    
    private func configureHeader(twitterStatus status: TwitterStatus) {
        if let _ = status.repost {
            status.author.publisher(for: \.name)
                .map { name -> StatusView.ViewModel.Header in
                    let userRepostText = L10n.Common.Controls.Status.userRetweeted(name)
                    let metaContent = PlaintextMetaContent(string: userRepostText)
                    let info = ViewModel.Header.RepostInfo(authorNameMetaContent: metaContent)
                    return .repost(info: info)
                }
                .assign(to: \.header, on: viewModel)
                .store(in: &disposeBag)
        } else {
            viewModel.header = .none
        }
    }
    
    private func configureAuthor(twitterStatus status: TwitterStatus) {
        let author = (status.repost ?? status).author
        // author avatar
        author.publisher(for: \.profileImageURL)
            .map { _ in author.avatarImageURL() }
            .assign(to: \.authorAvatarImageURL, on: viewModel)
            .store(in: &disposeBag)
        // author name
        author.publisher(for: \.name)
            .map { PlaintextMetaContent(string: $0) }
            .assign(to: \.authorName, on: viewModel)
            .store(in: &disposeBag)
        // author username
        author.publisher(for: \.username)
            .map { $0 as String? }
            .assign(to: \.authorUsername, on: viewModel)
            .store(in: &disposeBag)
        // timestamp
        (status.repost ?? status).publisher(for: \.createdAt)
            .map { $0 as Date? }
            .assign(to: \.timestamp, on: viewModel)
            .store(in: &disposeBag)
    }
    
    private func configureContent(twitterStatus status: TwitterStatus) {
        let status = status.repost ?? status
        let content = TwitterContent(content: status.text)
        let metaContent = TwitterMetaContent.convert(
            content: content,
            urlMaximumLength: 20,
            twitterTextProvider: OfficialTwitterTextProvider()
        )
        viewModel.content = metaContent
    }
    
    private func configureMedia(twitterStatus status: TwitterStatus) {
        MediaView.configuration(twitterStatus: status)
            .assign(to: \.mediaViewConfigurations, on: viewModel)
            .store(in: &disposeBag)
    }
    
    private func configureLocation(twitterStatus status: TwitterStatus) {
        let status = status.repost ?? status
        status.publisher(for: \.location)
            .map { $0?.fullName }
            .assign(to: \.location, on: viewModel)
            .store(in: &disposeBag)
    }
    
    private func configureToolbar(twitterStatus status: TwitterStatus) {
        let status = status.repost ?? status
        status.publisher(for: \.replyCount)
            .map(Int.init)
            .assign(to: \.replyCount, on: viewModel)
            .store(in: &disposeBag)
        status.publisher(for: \.repostCount)
            .map(Int.init)
            .assign(to: \.repostCount, on: viewModel)
            .store(in: &disposeBag)
        status.publisher(for: \.likeCount)
            .map(Int.init)
            .assign(to: \.likeCount, on: viewModel)
            .store(in: &disposeBag)

        // relationship
        Publishers.CombineLatest(
            AppContext.shared.authenticationService.activeAuthenticationContext,
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
            AppContext.shared.authenticationService.activeAuthenticationContext,
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
extension StatusView {
    func configure(
        mastodonStatus status: MastodonStatus,
        notification: MastodonNotification?
    ) {
        viewModel.objects.insert(status)
        
        configureHeader(mastodonStatus: status, mastodonNotification: notification)
        configureAuthor(mastodonStatus: status)
        configureContent(mastodonStatus: status)
        configureMedia(mastodonStatus: status)
        configureToolbar(mastodonStatus: status)
    }
    
    private func configureHeader(
        mastodonStatus status: MastodonStatus,
        mastodonNotification notification: MastodonNotification?
    ) {
        if let notification = notification {
            let user = notification.account
            let type = notification.notificationType
            Publishers.CombineLatest(
                user.publisher(for: \.displayName),
                user.publisher(for: \.emojis)
            )
            .map { _ in
                guard let info = NotificationHeaderInfo(type: type, user: user) else { return .none }
                return ViewModel.Header.notification(info: info)
            }
            .assign(to: \.header, on: viewModel)
            .store(in: &disposeBag)
        } else if let _ = status.repost {
            Publishers.CombineLatest(
                status.author.publisher(for: \.displayName),
                status.author.publisher(for: \.emojis)
            )
            .map { _, emojis -> StatusView.ViewModel.Header in
                let name = status.author.name
                let userRepostText = L10n.Common.Controls.Status.userBoosted(name)
                let content = MastodonContent(content: userRepostText, emojis: emojis.asDictionary)
                do {
                    let metaContent = try MastodonMetaContent.convert(document: content)
                    let info = ViewModel.Header.RepostInfo(authorNameMetaContent: metaContent)
                    return .repost(info: info)
                } catch {
                    assertionFailure(error.localizedDescription)
                    let metaContent = PlaintextMetaContent(string: userRepostText)
                    let info = ViewModel.Header.RepostInfo(authorNameMetaContent: metaContent)
                    return .repost(info: info)
                }
            }
            .assign(to: \.header, on: viewModel)
            .store(in: &disposeBag)
        } else {
            viewModel.header = .none
        }
    }
    
    private func configureAuthor(mastodonStatus status: MastodonStatus) {
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
        // author username
        author.publisher(for: \.acct)
            .map { $0 as String? }
            .assign(to: \.authorUsername, on: viewModel)
            .store(in: &disposeBag)
        // timestamp
        (status.repost ?? status).publisher(for: \.createdAt)
            .map { $0 as Date? }
            .assign(to: \.timestamp, on: viewModel)
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
    
    private func configureMedia(mastodonStatus status: MastodonStatus) {
        MediaView.configuration(mastodonStatus: status)
            .assign(to: \.mediaViewConfigurations, on: viewModel)
            .store(in: &disposeBag)
    }
    
    private func configureToolbar(mastodonStatus status: MastodonStatus) {
        let status = status.repost ?? status
        status.publisher(for: \.replyCount)
            .map(Int.init)
            .assign(to: \.replyCount, on: viewModel)
            .store(in: &disposeBag)
        status.publisher(for: \.repostCount)
            .map(Int.init)
            .assign(to: \.repostCount, on: viewModel)
            .store(in: &disposeBag)
        status.publisher(for: \.likeCount)
            .map(Int.init)
            .assign(to: \.likeCount, on: viewModel)
            .store(in: &disposeBag)
        
        // relationship
        Publishers.CombineLatest(
            AppContext.shared.authenticationService.activeAuthenticationContext,
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
            AppContext.shared.authenticationService.activeAuthenticationContext,
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
