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
import CoreDataStack
import TwitterMeta
import MastodonMeta
import Meta

extension StatusView {
    final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        
        @Published var platform: Platform = .none
        
        @Published var header: Header = .none
        
        @Published var authorAvatarImageURL: URL?
        @Published var authorName: String?
        @Published var authorUsername: String?
        
        @Published var content: String?
        @Published var mediaViewConfigurations: [MediaView.Configuration] = []
        @Published var location: String?
        
        @Published var replyCount: Int = 0
        @Published var repostCount: Int = 0
        @Published var likeCount: Int = 0
        
        @Published var timestamp: Date?
        
        enum Header {
            case none
            case repost(info: RepostInfo)
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
        Publishers.CombineLatest(
            $header,
            NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification).map { _ in }.prepend(Void())
        )
        .map { header, _ in header }
        .sink { header in
            switch header {
            case .none:
                return
            case .repost(let info):
                statusView.headerIconImageView.image = Asset.Media.repeat.image
                statusView.headerTextLabel.setupAttributes(style: StatusView.headerTextLabelStyle)
                statusView.headerTextLabel.configure(content: info.authorNameMetaContent)
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
        Publishers.CombineLatest(
            $authorName,
            NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification).map { _ in }.prepend(Void())
        )
        .map { text, _ in PlaintextMetaContent(string: text ?? "") }
        .sink { metaContent in
            statusView.authorNameLabel.setupAttributes(style: StatusView.authorNameLabelStyle)
            statusView.authorNameLabel.configure(content: metaContent)
        }
        .store(in: &disposeBag)
        // username
        Publishers.CombineLatest(
            $authorUsername,
            NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification).map { _ in }.prepend(Void())
        )
        .map { text, _ in
            guard let text = text else { return "" }
            return "@\(text)"
        }
        .assign(to: \.text, on: statusView.authorUsernameLabel)
        .store(in: &disposeBag)
        // timestamp
        Publishers.CombineLatest(
            $timestamp,
            AppContext.shared.timestampUpdatePublisher.map { _ in }.prepend(Void())
        )
        .sink { timestamp, _ in
            statusView.timestampLabel.text = timestamp?.shortTimeAgoSinceNow
        }
        .store(in: &disposeBag)
    }
    
    private func bindContent(statusView: StatusView) {
        Publishers.CombineLatest(
            $content,
            NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification).map { _ in }.prepend(Void())
        )
        .map { content, _ -> NSAttributedString in
            let textStyle = statusView.contentTextViewFontTextStyle ?? .body
            let textColor = statusView.contentTextViewTextColor ?? .label
            let attributedString = NSAttributedString(
                string: content ?? "",
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: textStyle),
                    .foregroundColor: textColor
                ]
            )
            return attributedString
        }
        .sink { attributedString in
            statusView.contentTextView.setAttributedString(attributedString)
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
        Publishers.CombineLatest(
            $location,
            NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification).map { _ in }.prepend(Void())
        )
        .sink { location, _ in
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
        $repostCount
            .sink { count in
                statusView.toolbar.setupRepost(count: count, isEnabled: true, isLocked: false)
            }
            .store(in: &disposeBag)
        $likeCount
            .sink { count in
                statusView.toolbar.setupLike(count: count)
            }
            .store(in: &disposeBag)
    }
}

extension StatusView {
    func configure(feed: Feed) {
        if let status = feed.twitterStatus {
            configure(twitterStatus: status)
        } else if let status = feed.mastodonStatus {
            configure(mastodonStatus: status)
        } else {
            assertionFailure()
        }
    }
}

// MARK: - Twitter

extension StatusView {
    func configure(twitterStatus status: TwitterStatus) {
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
            .map { $0 as String? }
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
        // TODO:
        viewModel.content = metaContent.trimmed
    }
    
    private func configureMedia(twitterStatus status: TwitterStatus) {
        func videoInfo(from attachment: TwitterAttachment) -> MediaView.Configuration.VideoInfo {
            MediaView.Configuration.VideoInfo(
                aspectRadio: attachment.size,
                assertURL: attachment.assetURL,
                previewURL: attachment.previewURL,
                durationMS: attachment.durationMS
            )
        }
        
        let status = status.repost ?? status
        status.publisher(for: \.attachments)
            .map { attachments -> [MediaView.Configuration] in
                return attachments.map { attachment -> MediaView.Configuration in
                    switch attachment.kind {
                    case .photo:
                        let info = MediaView.Configuration.ImageInfo(
                            aspectRadio: attachment.size,
                            assetURL: attachment.assetURL
                        )
                        return .image(info: info)
                    case .video:
                        let info = videoInfo(from: attachment)
                        return .video(info: info)
                    case .animatedGIF:
                        let info = videoInfo(from: attachment)
                        return .gif(info: info)
                    }
                }
            }
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
        status.publisher(for: \.replyCount).assign(to: \.replyCount, on: viewModel).store(in: &disposeBag)
        status.publisher(for: \.repostCount).assign(to: \.repostCount, on: viewModel).store(in: &disposeBag)
        status.publisher(for: \.likeCount).assign(to: \.likeCount, on: viewModel).store(in: &disposeBag)
    }
}

// MARK: - Mastodon
extension StatusView {
    func configure(mastodonStatus status: MastodonStatus) {
        configureHeader(mastodonStatus: status)
        configureAuthor(mastodonStatus: status)
        configureContent(mastodonStatus: status)
        configureMedia(mastodonStatus: status)
        configureToolbar(mastodonStatus: status)
    }
    
    private func configureHeader(mastodonStatus status: MastodonStatus) {
        if let _ = status.repost {
            status.author.publisher(for: \.displayName)
                .map { _ -> StatusView.ViewModel.Header in
                    let name = status.author.name
                    let userRepostText = L10n.Common.Controls.Status.userBoosted(name)
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
    
    private func configureAuthor(mastodonStatus status: MastodonStatus) {
        let author = (status.repost ?? status).author
        // author avatar
        author.publisher(for: \.avatar)
            .map { url in url.flatMap { URL(string: $0) } }
            .assign(to: \.authorAvatarImageURL, on: viewModel)
            .store(in: &disposeBag)
        // author name
        author.publisher(for: \.displayName)
            .map { _ in author.name }
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
        let content = MastodonContent(content: status.content, emojis: [:])
        do {
            let metaContent = try MastodonMetaContent.convert(document: content)
            // TODO:
            viewModel.content = metaContent.trimmed
        } catch {
            assertionFailure(error.localizedDescription)
            viewModel.content = ""
        }
    }
    
    private func configureMedia(mastodonStatus status: MastodonStatus) {
        func videoInfo(from attachment: MastodonAttachment) -> MediaView.Configuration.VideoInfo {
            MediaView.Configuration.VideoInfo(
                aspectRadio: attachment.size,
                assertURL: attachment.assetURL,
                previewURL: attachment.previewURL,
                durationMS: attachment.durationMS
            )
        }
        
        let status = status.repost ?? status
        status.publisher(for: \.attachments)
            .map { attachments -> [MediaView.Configuration] in
                return attachments.map { attachment -> MediaView.Configuration in
                    switch attachment.kind {
                    case .image:
                        let info = MediaView.Configuration.ImageInfo(
                            aspectRadio: attachment.size,
                            assetURL: attachment.assetURL
                        )
                        return .image(info: info)
                    case .video:
                        let info = videoInfo(from: attachment)
                        return .video(info: info)
                    case .gifv:
                        let info = videoInfo(from: attachment)
                        return .gif(info: info)
                    case .audio:
                        // TODO:
                        let info = videoInfo(from: attachment)
                        return .video(info: info)
                    }
                }
            }
            .assign(to: \.mediaViewConfigurations, on: viewModel)
            .store(in: &disposeBag)
    }
    
    private func configureToolbar(mastodonStatus status: MastodonStatus) {
        let status = status.repost ?? status
        status.publisher(for: \.replyCount).assign(to: \.replyCount, on: viewModel).store(in: &disposeBag)
        status.publisher(for: \.repostCount).assign(to: \.repostCount, on: viewModel).store(in: &disposeBag)
        status.publisher(for: \.likeCount).assign(to: \.likeCount, on: viewModel).store(in: &disposeBag)
    }
        
}
