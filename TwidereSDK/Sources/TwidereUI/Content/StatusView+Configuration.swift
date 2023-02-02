//
//  StatusView+Configuration.swift
//  
//
//  Created by MainasuK on 2022-6-10.
//

import os.log
import UIKit
import Combine
import SwiftUI
import CoreData
import CoreDataStack
import TwidereCommon
import TwidereCore
import TwitterMeta
import MastodonMeta
import Meta

extension StatusView {
    public struct ConfigurationContext {
        public let authContext: AuthContext
        public let dateTimeProvider: DateTimeProvider
        public let twitterTextProvider: TwitterTextProvider
        
        public init(
            authContext: AuthContext,
            dateTimeProvider: DateTimeProvider,
            twitterTextProvider: TwitterTextProvider
        ) {
            self.authContext = authContext
            self.dateTimeProvider = dateTimeProvider
            self.twitterTextProvider = twitterTextProvider
        }
    }
}

extension StatusView {
    public func configure(
        feed: Feed,
        configurationContext: ConfigurationContext
    ) {
        switch feed.content {
        case .none:
            logger.log(level: .info, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Warning] feed content missing")
        case .twitter(let status):
            configure(
                status: status,
                configurationContext: configurationContext
            )
        case .mastodon(let status):
            configure(
                status: status,
                notification: nil,
                configurationContext: configurationContext
            )
        case .mastodonNotification(let notification):
            guard let status = notification.status else {
                assertionFailure()
                return
            }
            configure(
                status: status,
                notification: notification,
                configurationContext: configurationContext
            )
        }
    }
    
    public func configure(
        statusObject object: StatusObject,
        configurationContext: ConfigurationContext
    ) {
        switch object {
        case .twitter(let status):
            configure(
                status: status,
                configurationContext: configurationContext
            )
        case .mastodon(let status):
            configure(
                status: status,
                notification: nil,
                configurationContext: configurationContext
            )
        }
    }
    
}

// MARK: - Twitter

extension StatusView {
    public func configure(
        status: TwitterStatus,
        configurationContext: ConfigurationContext
    ) {
        viewModel.prepareForReuse()
        
        viewModel.managedObjectContext = status.managedObjectContext
        viewModel.objects.insert(status)
        
        viewModel.platform = .twitter
        viewModel.dateTimeProvider = configurationContext.dateTimeProvider
        viewModel.twitterTextProvider = configurationContext.twitterTextProvider
        
        configureHeader(status)
        configureAuthor(status)
        configureContent(status)
        configureMedia(status)
        configurePoll(status)
        configureLocation(status)
        configureToolbar(status)
        configureReplySettings(status)
        
        if let quote = status.quote ?? status.repost?.quote {
            quoteStatusView?.configure(
                status: quote,
                configurationContext: configurationContext
            )
            setQuoteDisplay()
        }
    }
    
    private func configureHeader(_ status: TwitterStatus) {
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
    
    private func configureAuthor(_ status: TwitterStatus) {
        guard let dateTimeProvider = viewModel.dateTimeProvider else {
            assertionFailure()
            return
        }
        
        let author = (status.repost ?? status).author
        
        viewModel.userIdentifier = .twitter(.init(id: author.id))
        
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
        // author username
        author.publisher(for: \.username)
            .map { $0 as String? }
            .assign(to: \.authorUsername, on: viewModel)
            .store(in: &disposeBag)
        // timestamp
        viewModel.dateTimeProvider = dateTimeProvider
        (status.repost ?? status).publisher(for: \.createdAt)
            .map { $0 as Date? }
            .assign(to: \.timestamp, on: viewModel)
            .store(in: &disposeBag)
    }
    
    private func configureContent(_ status: TwitterStatus) {
        guard let twitterTextProvider = viewModel.twitterTextProvider else {
            assertionFailure()
            return
        }
        
        let status = status.repost ?? status
        let content = TwitterContent(content: status.displayText)
        let metaContent = TwitterMetaContent.convert(
            content: content,
            urlMaximumLength: 20,
            twitterTextProvider: twitterTextProvider
        )
        viewModel.spoilerContent = nil
        viewModel.isContentReveal = true
        viewModel.isContentSensitive = false
        viewModel.isContentSensitiveToggled = false
        viewModel.content = metaContent
        viewModel.sharePlaintextContent = status.displayText
        viewModel.language = status.language
        viewModel.source = status.source
    }
    
    private func configureMedia(_ status: TwitterStatus) {
        let status = status.repost ?? status
        
        mediaGridContainerView.viewModel.resetContentWarningOverlay()
        viewModel.isMediaSensitive = false
        viewModel.isMediaSensitiveToggled = false
        viewModel.isMediaSensitiveSwitchable = false
        viewModel.mediaViewConfigurations = MediaView.configuration(twitterStatus: status)
    }
    
    private func configurePoll(_ status: TwitterStatus) {
        let status = status.repost ?? status
        
        // pollItems
        status.publisher(for: \.poll)
            .sink { [weak self] poll in
                guard let self = self else { return }
                guard let poll = poll else {
                    self.viewModel.pollItems = []
                    return
                }
                
                let options = poll.options.sorted(by: { $0.position < $1.position })
                let items: [PollItem] = options.map { .option(record: .twitter(record: .init(objectID: $0.objectID))) }
                self.viewModel.pollItems = items
            }
            .store(in: &disposeBag)
        // isVoteButtonEnabled
        viewModel.isVoteButtonEnabled = false
        // isVotable
        viewModel.isVotable = false
        // votesCount
        if let poll = status.poll {
            poll.publisher(for: \.updatedAt)
                .map { _ in poll.options.map { Int($0.votes) }.reduce(0, +) }
                .assign(to: \.voteCount, on: viewModel)
                .store(in: &disposeBag)
        }
        // voterCount
        // none
        // expireAt
        viewModel.expireAt = status.poll?.endDatetime
        // expired
        viewModel.expired = status.poll?.votingStatus == .closed
        // isVoting
        viewModel.isVoting = false
    }
    
    private func configureLocation(_ status: TwitterStatus) {
        let status = status.repost ?? status
        status.publisher(for: \.location)
            .map { $0?.fullName }
            .assign(to: \.location, on: viewModel)
            .store(in: &disposeBag)
    }
    
    private func configureToolbar(_ status: TwitterStatus) {
        let status = status.repost ?? status
        
        status.publisher(for: \.replyCount)
            .map(Int.init)
            .assign(to: \.replyCount, on: viewModel)
            .store(in: &disposeBag)
        status.publisher(for: \.repostCount)
            .map(Int.init)
            .assign(to: \.repostCount, on: viewModel)
            .store(in: &disposeBag)
        status.publisher(for: \.quoteCount)
            .map(Int.init)
            .assign(to: \.quoteCount, on: viewModel)
            .store(in: &disposeBag)
        status.publisher(for: \.likeCount)
            .map(Int.init)
            .assign(to: \.likeCount, on: viewModel)
            .store(in: &disposeBag)
        viewModel.shareStatusURL = status.statusURL.absoluteString
        
        // relationship
        Publishers.CombineLatest(
            viewModel.$authenticationContext,
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
            viewModel.$authenticationContext,
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
        
        let authorUserID = status.author.id
        viewModel.$authenticationContext
            .map { authenticationContext in
                guard let authenticationContext = authenticationContext?.twitterAuthenticationContext else {
                    return false
                }
                return authenticationContext.userID == authorUserID
            }
            .assign(to: \.isDeletable, on: viewModel)
            .store(in: &disposeBag)
    }
    
    func configureReplySettings(_ status: TwitterStatus) {
        let status = status.repost ?? status
        
        viewModel.replySettings = status.replySettings?.typed
    }
    
}

// MARK: - Mastodon

extension StatusView {
    public func configure(
        status: MastodonStatus,
        notification: MastodonNotification?,
        configurationContext: ConfigurationContext
    ) {
        viewModel.prepareForReuse()
        
        viewModel.managedObjectContext = status.managedObjectContext
        viewModel.objects.insert(status)
        
        viewModel.platform = .mastodon
        viewModel.dateTimeProvider = configurationContext.dateTimeProvider
        viewModel.twitterTextProvider = configurationContext.twitterTextProvider

        configureHeader(status, notification: notification)
        configureAuthor(status)
        configureContent(status)
        configureMedia(status)
        configurePoll(status)
        configureToolbar(status)
    }
    
    private func configureHeader(
        _ status: MastodonStatus,
        notification: MastodonNotification?
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
    
    private func configureAuthor(_ status: MastodonStatus) {
        let author = (status.repost ?? status).author
        
        viewModel.userIdentifier = .mastodon(.init(domain: author.domain, id: author.id))
        
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
            do {
                let content = MastodonContent(content: author.name, emojis: emojis.asDictionary)
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
        // protected
        author.publisher(for: \.locked)
            .assign(to: \.protected, on: viewModel)
            .store(in: &disposeBag)
        // visibility
        viewModel.visibility = status.visibility.asStatusVisibility
        // timestamp
        (status.repost ?? status).publisher(for: \.createdAt)
            .map { $0 as Date? }
            .assign(to: \.timestamp, on: viewModel)
            .store(in: &disposeBag)
    }
    
    private func configureContent(_ status: MastodonStatus) {
        let status = status.repost ?? status
        do {
            let content = MastodonContent(content: status.content, emojis: status.emojis.asDictionary)
            let metaContent = try MastodonMetaContent.convert(document: content)
            viewModel.content = metaContent
            viewModel.sharePlaintextContent = metaContent.original
        } catch {
            assertionFailure(error.localizedDescription)
            viewModel.content = PlaintextMetaContent(string: "")
        }
        
        if let spoilerText = status.spoilerText, !spoilerText.isEmpty {
            do {
                let content = MastodonContent(content: spoilerText, emojis: status.emojis.asDictionary)
                let metaContent = try MastodonMetaContent.convert(document: content)
                viewModel.spoilerContent = metaContent
            } catch {
                assertionFailure()
                viewModel.spoilerContent = nil
            }
        } else {
            viewModel.spoilerContent = nil
        }
        
        viewModel.isContentSensitiveToggled = status.isContentSensitiveToggled
        status.publisher(for: \.isContentSensitiveToggled)
            .assign(to: \.isContentSensitiveToggled, on: viewModel)
            .store(in: &disposeBag)
        
        viewModel.language = status.language
        viewModel.source = status.source
    }
    
    private func configureMedia(_ status: MastodonStatus) {
        let status = status.repost ?? status
        
        mediaGridContainerView.viewModel.resetContentWarningOverlay()
        viewModel.isMediaSensitiveSwitchable = true
        viewModel.mediaViewConfigurations = MediaView.configuration(mastodonStatus: status)
        
        // set directly without delay
        viewModel.isMediaSensitiveToggled = status.isMediaSensitiveToggled
        viewModel.isMediaSensitive = status.isMediaSensitive
        mediaGridContainerView.configureOverlayDisplay(
            isDisplay: status.isMediaSensitiveToggled ? !status.isMediaSensitive : !status.isMediaSensitive,
            animated: false
        )
        
        status.publisher(for: \.isMediaSensitiveToggled)
            .receive(on: DispatchQueue.main)
            .assign(to: \.isMediaSensitiveToggled, on: viewModel)
            .store(in: &disposeBag)
    }
    
    private func configurePoll(_ status: MastodonStatus) {
        let status = status.repost ?? status
        
        // pollItems
        status.publisher(for: \.poll)
            .sink { [weak self] poll in
                guard let self = self else { return }
                guard let poll = poll else {
                    self.viewModel.pollItems = []
                    return
                }
                
                let options = poll.options.sorted(by: { $0.index < $1.index })
                let items: [PollItem] = options.map { .option(record: .mastodon(record: .init(objectID: $0.objectID))) }
                self.viewModel.pollItems = items
            }
            .store(in: &disposeBag)
        // isVoteButtonEnabled
        status.poll?.publisher(for: \.updatedAt)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard let poll = status.poll else { return }
                let options = poll.options
                let hasSelectedOption = options.contains(where: { $0.isSelected })
                self.viewModel.isVoteButtonEnabled = hasSelectedOption
            }
            .store(in: &disposeBag)
        // isVotable
        if let poll = status.poll {
            Publishers.CombineLatest3(
                poll.publisher(for: \.voteBy),
                poll.publisher(for: \.expired),
                viewModel.$authenticationContext
            )
            .map { voteBy, expired, authenticationContext in
                guard case let .mastodon(authenticationContext) = authenticationContext else { return false }
                let domain = authenticationContext.domain
                let userID = authenticationContext.userID
                let isVoted = voteBy.contains(where: { $0.domain == domain && $0.id == userID })
                return !isVoted && !expired
            }
            .assign(to: &viewModel.$isVotable)
        }
        // votesCount
        status.poll?.publisher(for: \.votesCount)
            .map { Int($0) }
            .assign(to: \.voteCount, on: viewModel)
            .store(in: &disposeBag)
        // voterCount
        status.poll?.publisher(for: \.votersCount)
            .map { Int($0) }
            .assign(to: \.voterCount, on: viewModel)
            .store(in: &disposeBag)
        // expireAt
        status.poll?.publisher(for: \.expiresAt)
            .assign(to: \.expireAt, on: viewModel)
            .store(in: &disposeBag)
        // expired
        status.poll?.publisher(for: \.expired)
            .assign(to: \.expired, on: viewModel)
            .store(in: &disposeBag)
        // isVoting
        status.poll?.publisher(for: \.isVoting)
            .assign(to: \.isVoting, on: viewModel)
            .store(in: &disposeBag)
    }
    
    private func configureToolbar(_ status: MastodonStatus) {
        let status = status.repost ?? status
        
        viewModel.quoteCount = 0
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
        viewModel.shareStatusURL = status.url ?? status.uri
        
        // relationship
        Publishers.CombineLatest(
            viewModel.$authenticationContext,
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
            viewModel.$authenticationContext,
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
        
        let authorUserID = status.author.id
        viewModel.$authenticationContext
            .map { authenticationContext in
                guard let authenticationContext = authenticationContext?.mastodonAuthenticationContext else {
                    return false
                }
                return authenticationContext.userID == authorUserID
            }
            .assign(to: \.isDeletable, on: viewModel)
            .store(in: &disposeBag)
    }
        
}
