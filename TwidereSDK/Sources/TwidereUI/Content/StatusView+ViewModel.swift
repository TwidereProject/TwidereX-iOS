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
import TwidereCommon
import TwidereCore
import TwitterMeta
import MastodonMeta
import Meta

extension StatusView {
    public final class ViewModel: ObservableObject {
        static let pollOptionOrdinalNumberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .ordinal
            return formatter
        }()
        
        var disposeBag = Set<AnyCancellable>()
        var observations = Set<NSKeyValueObservation>()
        var objects = Set<NSManagedObject>()
        
        let logger = Logger(subsystem: "StatusView", category: "ViewModel")
        
        @Published public var platform: Platform = .none
        @Published public var authenticationContext: AuthenticationContext?       // me
        @Published public var managedObjectContext: NSManagedObjectContext?
        
        @Published public var header: Header = .none
        
        @Published public var authorAvatarImage: UIImage?
        @Published public var authorAvatarImageURL: URL?
        @Published public var authorName: MetaContent?
        @Published public var authorUsername: String?
        
        @Published public var protected: Bool = false

        @Published public var isMyself = false

        @Published public var spoilerContent: MetaContent?
        
        @Published public var content: MetaContent?
        @Published public var twitterTextProvider: TwitterTextProvider?
        
        @Published public var mediaViewConfigurations: [MediaView.Configuration] = []
        
        @Published public var isContentSensitive: Bool = false
        @Published public var isContentSensitiveToggled: Bool = true
        
        @Published public var isContentReveal: Bool = false
        
        @Published public var isMediaSensitive: Bool = false
        @Published public var isMediaSensitiveToggled: Bool = false
            
        @Published public var isMediaSensitiveSwitchable = false
        @Published public var isMediaReveal: Bool = false
        
        // poll input
        @Published public var pollItems: [PollItem] = []
        @Published public var isVotable: Bool = false
        @Published public var isVoting: Bool = false
        @Published public var isVoteButtonEnabled: Bool = false
        @Published public var voterCount: Int?
        @Published public var voteCount = 0
        @Published public var expireAt: Date?
        @Published public var expired: Bool = false
        
        // poll output
        @Published public var pollVoteDescription = ""
        @Published public var pollCountdownDescription: String?
        
        @Published public var location: String?
        @Published public var source: String?
        
        @Published public var isRepost = false
        @Published public var isRepostEnabled = true
        
        @Published public var isLike = false
        
        @Published public var replyCount: Int = 0
        @Published public var repostCount: Int = 0
        @Published public var quoteCount: Int = 0
        @Published public var likeCount: Int = 0
        
        @Published public var visibility: StatusVisibility?
        
        @Published public var dateTimeProvider: DateTimeProvider?
        @Published public var timestamp: Date?
        @Published public var timeAgoStyleTimestamp: String?
        @Published public var formattedStyleTimestamp: String?
        
        @Published public var sharePlaintextContent: String?
        @Published public var shareStatusURL: String?
        
        @Published public var isDeletable = false
        
        @Published public var groupedAccessibilityLabel = ""
        
        let timestampUpdatePublisher = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .share()
            .eraseToAnyPublisher()
        
        // public let contentRevealChangePublisher = PassthroughSubject<Void, Never>()
        
        public enum Header {
            case none
            case repost(info: RepostInfo)
            case notification(info: NotificationHeaderInfo)
            // TODO: replyTo
            
            public struct RepostInfo {
                public let authorNameMetaContent: MetaContent
            }
        }
        
        init() {
            // isContentReveal
            Publishers.CombineLatest(
                $isContentSensitive,
                $isContentSensitiveToggled
            )
            .map { $0 ? $1 : !$1 }
            .assign(to: &$isContentReveal)
            // isMediaReveal
            Publishers.CombineLatest(
                $isMediaSensitive,
                $isMediaSensitiveToggled
            )
            .map { $0 ? $1 : !$1 }
            .assign(to: &$isMediaReveal)
            // isRepostEnabled
            Publishers.CombineLatest4(
                $platform,
                $visibility,
                $protected,
                $isMyself
            )
            .map { platform, visibility, protected, isMyself in
                switch platform {
                case .none:
                    return true
                case .twitter:
                    return isMyself ? true : !protected
                case .mastodon:
                    if isMyself {
                        return true
                    }
                    switch visibility {
                    case .none:
                        return true
                    case .mastodon(let visibility):
                        switch visibility {
                        case .public, .unlisted:
                            return true
                        case .private, .direct, ._other:
                            return false
                        }
                    }
                }
            }
            .assign(to: &$isRepostEnabled)
        }
    }
}

extension StatusView.ViewModel {
    func bind(statusView: StatusView) {
        bindHeader(statusView: statusView)
        bindAuthor(statusView: statusView)
        bindContent(statusView: statusView)
        bindMedia(statusView: statusView)
        bindPoll(statusView: statusView)
        bindLocation(statusView: statusView)
        bindToolbar(statusView: statusView)
        bindAccessibility(statusView: statusView)
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
        Publishers.CombineLatest(
            $authorAvatarImage,
            $authorAvatarImageURL
        )
        .sink { image, url in
            let configuration: AvatarImageView.Configuration = {
                if let image = image {
                    return AvatarImageView.Configuration(image: image)
                } else {
                    return AvatarImageView.Configuration(url: url)
                }
            }()
            statusView.authorAvatarButton.avatarImageView.configure(configuration: configuration)
        }
        .store(in: &disposeBag)
        UserDefaults.shared
            .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
                
                let avatarStyle = defaults.avatarStyle
                let animator = UIViewPropertyAnimator(duration: 0.3, timingParameters: UISpringTimingParameters())
                animator.addAnimations {
                    switch avatarStyle {
                    case .circle:
                        statusView.authorAvatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .circle))
                    case .roundedSquare:
                        statusView.authorAvatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .scale(ratio: 4)))
                    }
                }
                animator.startAnimation()
            }
            .store(in: &observations)
        // lock
        $protected
            .sink { protected in
                statusView.lockImageView.isHidden = !protected
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
        // visibility
        $visibility
            .sink { visibility in
                guard let visibility = visibility,
                      let image = visibility.inlineImage
                else { return }
                
                statusView.visibilityImageView.image = image
                statusView.visibilityImageView.accessibilityLabel = visibility.accessibilityLabel
                statusView.visibilityImageView.accessibilityTraits = .staticText
                statusView.visibilityImageView.isAccessibilityElement = true
                statusView.setVisibilityDisplay()
            }
            .store(in: &disposeBag)
        // timestamp
        Publishers.CombineLatest3(
            $timestamp,
            $dateTimeProvider,
            timestampUpdatePublisher.prepend(Date()).eraseToAnyPublisher()
        )
        .sink { [weak self] timestamp, dateTimeProvider, _ in
            guard let self = self else { return }
            self.timeAgoStyleTimestamp = dateTimeProvider?.shortTimeAgoSinceNow(to: timestamp)
            self.formattedStyleTimestamp = {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .medium
                let text = timestamp.flatMap { formatter.string(from: $0) }
                return text
            }()
        }
        .store(in: &disposeBag)
        $timeAgoStyleTimestamp
            .sink { timestamp in
                statusView.timestampLabel.text = timestamp
            }
            .store(in: &disposeBag)
        $formattedStyleTimestamp
            .sink { timestamp in
                statusView.metricsDashboardView.timestampLabel.text = timestamp
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
        $spoilerContent
            .sink { metaContent in
                guard let metaContent = metaContent else {
                    statusView.spoilerContentTextView.reset()
                    return
                }
                statusView.spoilerContentTextView.configure(content: metaContent)
                statusView.setSpoilerDisplay()
            }
            .store(in: &disposeBag)
        $isContentReveal
            .sink { isContentReveal in
                statusView.contentTextView.isHidden = !isContentReveal
                
                let label = isContentReveal ? L10n.Accessibility.Common.Status.Actions.hideContent : L10n.Accessibility.Common.Status.Actions.revealContent
                statusView.expandContentButton.accessibilityLabel = label
            }
            .store(in: &disposeBag)
        $source
            .sink { source in
                statusView.metricsDashboardView.sourceLabel.text = source ?? ""
            }
            .store(in: &disposeBag)
        // dashboard
        $platform
            .assign(to: \.platform, on: statusView.metricsDashboardView.viewModel)
            .store(in: &disposeBag)
        Publishers.CombineLatest4(
            $replyCount,
            $repostCount,
            $quoteCount,
            $likeCount
        )
        .sink { replyCount, repostCount, quoteCount, likeCount in
            switch statusView.style {
            case .plain:
                statusView.metricsDashboardView.viewModel.replyCount = replyCount
                statusView.metricsDashboardView.viewModel.repostCount = repostCount
                statusView.metricsDashboardView.viewModel.quoteCount = quoteCount
                statusView.metricsDashboardView.viewModel.likeCount = likeCount
            default:
                break
            }
        }
        .store(in: &disposeBag)
    }
    
    private func bindMedia(statusView: StatusView) {
        $mediaViewConfigurations
            .sink { [weak self] configurations in
                guard let self = self else { return }
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): configure media")
                
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
        $isMediaReveal
            .sink { isMediaReveal in
                statusView.mediaGridContainerView.viewModel.isContentWarningOverlayDisplay = !isMediaReveal
            }
            .store(in: &disposeBag)
        $isMediaSensitiveSwitchable
            .sink { isMediaSensitiveSwitchable in
                statusView.mediaGridContainerView.viewModel.isSensitiveToggleButtonDisplay = isMediaSensitiveSwitchable
            }
            .store(in: &disposeBag)
    }
    
    private func bindPoll(statusView: StatusView) {
        $pollItems
            .sink { items in
                guard !items.isEmpty else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<PollSection, PollItem>()
                snapshot.appendSections([.main])
                snapshot.appendItems(items, toSection: .main)
                statusView.pollTableViewDiffableDataSource?.applySnapshotUsingReloadData(snapshot)
                
                statusView.pollTableViewHeightLayoutConstraint.constant = CGFloat(items.count) * PollOptionTableViewCell.height
                statusView.setPollDisplay()
            }
            .store(in: &disposeBag)
        $isVotable
            .sink { isVotable in
                statusView.pollTableView.allowsSelection = isVotable
            }
            .store(in: &disposeBag)
        // poll
        Publishers.CombineLatest(
            $voterCount,
            $voteCount
        )
        .map { voterCount, voteCount -> String in
            var description = ""
            if let voterCount = voterCount {
                description += L10n.Count.people(voterCount)
            } else {
                description += L10n.Count.vote(voteCount)
            }
            return description
        }
        .assign(to: &$pollVoteDescription)
        Publishers.CombineLatest3(
            $expireAt,
            $expired,
            timestampUpdatePublisher.prepend(Date()).eraseToAnyPublisher()
        )
        .map { expireAt, expired, _ -> String? in
            guard !expired else {
                return L10n.Common.Controls.Status.Poll.expired
            }
            
            guard let expireAt = expireAt,
                  let timeLeft = expireAt.localizedTimeLeft
            else {
                return nil
            }
            
            return timeLeft
        }
        .assign(to: &$pollCountdownDescription)
        Publishers.CombineLatest(
            $pollVoteDescription,
            $pollCountdownDescription
        )
        .sink { pollVoteDescription, pollCountdownDescription in
            let description = [
                pollVoteDescription,
                pollCountdownDescription
            ]
            .compactMap { $0 }
            
            statusView.pollVoteDescriptionLabel.text = description.joined(separator: " · ")
            statusView.pollVoteDescriptionLabel.accessibilityLabel = description.joined(separator: ", ")
        }
        .store(in: &disposeBag)
        Publishers.CombineLatest(
            $isVotable,
            $isVoting
        )
        .sink { isVotable, isVoting in
            guard isVotable else {
                statusView.pollVoteButton.isHidden = true
                statusView.pollVoteActivityIndicatorView.isHidden = true
                return
            }
            
            statusView.pollVoteButton.isHidden = isVoting
            statusView.pollVoteActivityIndicatorView.isHidden = !isVoting
            statusView.pollVoteActivityIndicatorView.startAnimating()
        }
        .store(in: &disposeBag)
        $isVoteButtonEnabled
            .assign(to: \.isEnabled, on: statusView.pollVoteButton)
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
        // platform
        $platform
            .assign(to: \.platform, on: statusView.toolbar.viewModel)
            .store(in: &disposeBag)
        // reply
        $replyCount
            .sink { count in
                statusView.toolbar.setupReply(count: count, isEnabled: true)    // TODO:
            }
            .store(in: &disposeBag)
        // repost
        Publishers.CombineLatest3(
            $repostCount,
            $isRepost,
            $isRepostEnabled
        )
        .sink { count, isRepost, isEnabled in
            statusView.toolbar.setupRepost(count: count, isEnabled: isEnabled, isHighlighted: isRepost)
        }
        .store(in: &disposeBag)
        // like
        Publishers.CombineLatest(
            $likeCount,
            $isLike
        )
        .sink { count, isLike in
            statusView.toolbar.setupLike(count: count, isHighlighted: isLike)
        }
        .store(in: &disposeBag)
        // menu
        Publishers.CombineLatest3(
            $sharePlaintextContent,
            $shareStatusURL,
            $isDeletable
        )
        .sink { sharePlaintextContent, shareStatusURL, isDeletable in
            statusView.toolbar.setupMenu(menuContext: .init(
                shareText: sharePlaintextContent,
                shareLink: shareStatusURL,
                displayDeleteAction: isDeletable
            ))
        }
        .store(in: &disposeBag)
    }
    
    private func bindAccessibility(statusView: StatusView) {
        let authorAccessibilityLabel = Publishers.CombineLatest(
            $header,
            $authorName
        )
        .map { header, authorName -> String? in
            var strings: [String?] = []
            
            switch header {
            case .none:
                break
            case .notification(let info):
                strings.append(info.textMetaContent.string)
            case .repost(let info):
                strings.append(info.authorNameMetaContent.string)
            }
            
            strings.append(authorName?.string)
            
            return strings.compactMap { $0 }.joined(separator: ", ")
        }
        
        let metaAccessibilityLabel = Publishers.CombineLatest(
            $timeAgoStyleTimestamp,
            $visibility
        )
        .map { timestamp, visibility -> String? in
            var strings: [String?] = []
            
            strings.append(visibility?.accessibilityLabel)
            strings.append(timestamp)
            
            return strings.compactMap { $0 }.joined(separator: ", ")
        }
        
        let contentAccessibilityLabel = Publishers.CombineLatest4(
            $platform,
            $isContentReveal,
            $spoilerContent,
            $content
        )
        .map { platform, isContentReveal, spoilerContent, content -> String? in
            var strings: [String?] = []
            switch platform {
            case .none:
                break
            case .twitter:
                strings.append(content?.string)
            case .mastodon:
                if let spoilerContent = spoilerContent?.string {
                    strings.append(L10n.Accessibility.Common.Status.contentWarning)
                    strings.append(spoilerContent)
                }
                if isContentReveal {
                    strings.append(content?.string)
                }
            }
            
            return strings.compactMap { $0 }.joined(separator: ", ")
        }
        
        let mediaAccessibilityLabel = $mediaViewConfigurations
            .map { configurations -> String? in
                let count = configurations.count
                return count > 0 ? L10n.Count.media(count) : nil
            }
        
        let toolbarAccessibilityLabel = Publishers.CombineLatest3(
            $platform,
            $isRepost,
            $isLike
        )
        .map { platform, isRepost, isLike -> String? in
            var strings: [String?] = []
            
            switch platform {
            case .none:
                break
            case .twitter:
                if isRepost {
                    strings.append(L10n.Accessibility.Common.Status.retweeted)
                }
            case .mastodon:
                if isRepost {
                    strings.append(L10n.Accessibility.Common.Status.boosted)
                }
            }
            
            if isLike {
                strings.append(L10n.Accessibility.Common.Status.liked)
            }
            
            return strings.compactMap { $0 }.joined(separator: ", ")
        }
        
        let pollAccessibilityLabel = Publishers.CombineLatest3(
                $pollItems,
                $pollVoteDescription,
                $pollCountdownDescription
            )
            .map { items, pollVoteDescription, pollCountdownDescription -> String? in
                guard let managedObjectContext = self.managedObjectContext else { return nil }
                
                var strings: [String?] = []
                
                let ordinalPrefix = L10n.Accessibility.Common.Status.pollOptionOrdinalPrefix
                
                for (i, item) in items.enumerated() {
                    switch item {
                    case .option(let record):
                        guard let option = record.object(in: managedObjectContext) else { continue }
                        let number = NSNumber(value: i + 1)
                        guard let ordinal = StatusView.ViewModel.pollOptionOrdinalNumberFormatter.string(from: number) else { break }
                        strings.append("\(ordinalPrefix), \(ordinal), \(option.title)")
                        
                        if option.isSelected {
                            strings.append(L10n.Accessibility.VoiceOver.selected)
                        }
                    }
                }
                
                strings.append(pollVoteDescription)
                pollCountdownDescription.flatMap { strings.append($0) }
                
                return strings.compactMap { $0 }.joined(separator: ", ")
            }
        
        let groupOne = Publishers.CombineLatest4(
            authorAccessibilityLabel,
            metaAccessibilityLabel,
            contentAccessibilityLabel,
            mediaAccessibilityLabel
        )
        .map { a, b, c, d -> String? in
            return [a, b, c, d]
                .compactMap { $0 }
                .joined(separator: ", ")
        }
        
        let groupTwo = Publishers.CombineLatest(
            toolbarAccessibilityLabel,
            pollAccessibilityLabel
        )
        .map { a, b -> String? in
            return [a, b]
                .compactMap { $0 }
                .joined(separator: ", ")
        }
            
        Publishers.CombineLatest(
            groupOne,
            groupTwo
        )
        .map { a, b -> String in
            return [a, b]
                .compactMap { $0 }
                .joined(separator: ", ")
        }
        .assign(to: &$groupedAccessibilityLabel)
        
        $groupedAccessibilityLabel
            .sink { accessibilityLabel in
                statusView.accessibilityLabel = accessibilityLabel
            }
            .store(in: &disposeBag)
        
        // poll
        $pollItems
            .sink { items in
                statusView.pollVoteDescriptionLabel.isAccessibilityElement = !items.isEmpty
                statusView.pollVoteButton.isAccessibilityElement = !items.isEmpty
            }
            .store(in: &disposeBag)
    }

}

extension StatusView {
    public struct ConfigurationContext {
        public let dateTimeProvider: DateTimeProvider
        public let twitterTextProvider: TwitterTextProvider
        public let authenticationContext: Published<AuthenticationContext?>.Publisher
        
        public init(
            dateTimeProvider: DateTimeProvider,
            twitterTextProvider: TwitterTextProvider,
            authenticationContext: Published<AuthenticationContext?>.Publisher
        ) {
            self.dateTimeProvider = dateTimeProvider
            self.twitterTextProvider = twitterTextProvider
            self.authenticationContext = authenticationContext
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
                twitterStatus: status,
                configurationContext: configurationContext
            )
        case .mastodon(let status):
            configure(
                mastodonStatus: status,
                notification: nil,
                configurationContext: configurationContext
            )
        case .mastodonNotification(let notification):
            guard let status = notification.status else {
                assertionFailure()
                return
            }
            configure(
                mastodonStatus: status,
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
                twitterStatus: status,
                configurationContext: configurationContext
            )
        case .mastodon(let status):
            configure(
                mastodonStatus: status,
                notification: nil,
                configurationContext: configurationContext
            )
        }
    }
    
}

// MARK: - Twitter

extension StatusView {
    public func configure(
        twitterStatus status: TwitterStatus,
        configurationContext: ConfigurationContext
    ) {
        viewModel.managedObjectContext = status.managedObjectContext
        viewModel.objects.insert(status)
        
        viewModel.platform = .twitter
        viewModel.dateTimeProvider = configurationContext.dateTimeProvider
        viewModel.twitterTextProvider = configurationContext.twitterTextProvider
        configurationContext.authenticationContext.assign(to: \.authenticationContext, on: viewModel).store(in: &disposeBag)
        
        configureHeader(twitterStatus: status)
        configureAuthor(twitterStatus: status)
        configureContent(twitterStatus: status)
        configureMedia(twitterStatus: status)
        configureLocation(twitterStatus: status)
        configureToolbar(twitterStatus: status)
        
        if let quote = status.quote {
            quoteStatusView?.configure(
                twitterStatus: quote,
                configurationContext: configurationContext
            )
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
        guard let dateTimeProvider = viewModel.dateTimeProvider else {
            assertionFailure()
            return
        }
        
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
    
    private func configureContent(twitterStatus status: TwitterStatus) {
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
        viewModel.source = status.source
    }
    
    private func configureMedia(twitterStatus status: TwitterStatus) {
        let status = status.repost ?? status
        
        mediaGridContainerView.viewModel.resetContentWarningOverlay()
        viewModel.isMediaSensitive = false
        viewModel.isMediaSensitiveToggled = false
        viewModel.isMediaSensitiveSwitchable = false
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
}

// MARK: - Mastodon
extension StatusView {
    public func configure(
        mastodonStatus status: MastodonStatus,
        notification: MastodonNotification?,
        configurationContext: ConfigurationContext
    ) {
        viewModel.managedObjectContext = status.managedObjectContext
        viewModel.objects.insert(status)
        
        viewModel.platform = .mastodon
        viewModel.dateTimeProvider = configurationContext.dateTimeProvider
        viewModel.twitterTextProvider = configurationContext.twitterTextProvider
        configurationContext.authenticationContext.assign(to: \.authenticationContext, on: viewModel).store(in: &disposeBag)

        configureHeader(mastodonStatus: status, mastodonNotification: notification)
        configureAuthor(mastodonStatus: status)
        configureContent(mastodonStatus: status)
        configureMedia(mastodonStatus: status)
        configurePoll(mastodonStatus: status)
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
    
    private func configureContent(mastodonStatus status: MastodonStatus) {
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
        
        viewModel.source = status.source
    }
    
    private func configureMedia(mastodonStatus status: MastodonStatus) {
        let status = status.repost ?? status
        
        mediaGridContainerView.viewModel.resetContentWarningOverlay()
        viewModel.isMediaSensitiveSwitchable = true
        
        MediaView.configuration(mastodonStatus: status)
            .assign(to: \.mediaViewConfigurations, on: viewModel)
            .store(in: &disposeBag)
        
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
    
    private func configurePoll(mastodonStatus status: MastodonStatus) {
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
                let items: [PollItem] = options.map { .option(record: .init(objectID: $0.objectID)) }
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
    
    private func configureToolbar(mastodonStatus status: MastodonStatus) {
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
