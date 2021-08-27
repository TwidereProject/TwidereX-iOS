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
import MastodonMeta

extension StatusView {
    final class ViewModel: ObservableObject {
        
        var disposeBag = Set<AnyCancellable>()
        
        @Published var platform: Platform = .none
        
        @Published var authorAvatarImageURL: URL?
        @Published var authorName: String?
        @Published var authorUsername: String?
        
        @Published var content: String?
        
        @Published var timestamp: Date?
    }
}

extension StatusView.ViewModel {
    func bind(statusView: StatusView) {
        bindAuthor(statusView: statusView)
        bindContent(statusView: statusView)
    }
    
    func bindAuthor(statusView: StatusView) {
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
    
    func bindContent(statusView: StatusView) {
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
}

extension StatusView {
    func configure(feed: Feed) {
        if let twitterStatus = feed.twitterStatus {
            // TODO:
        } else if let mastodonStatus = feed.mastodonStatus  {
            configure(mastodonStatus: mastodonStatus)
        } else {
            assertionFailure()
        }
    }
}

extension StatusView {
    func configure(mastodonStatus status: MastodonStatus) {
        configureAuthor(mastodonStatus: status)
        configureContent(mastodonStatus: status)
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
        let status = (status.repost ?? status)
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
}
