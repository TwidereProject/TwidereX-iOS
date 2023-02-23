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
import TwidereAsset
import TwidereLocalization
import TwidereCore
import TwitterMeta
import MastodonMeta
import Meta
import TwitterSDK
import MastodonSDK

extension StatusView {
    public final class ViewModel: ObservableObject {
        
        let logger = Logger(subsystem: "StatusView", category: "ViewModel")
        
        var disposeBag = Set<AnyCancellable>()
        
        @Published public var viewLayoutFrame = ViewLayoutFrame()
                
        @Published public var repostViewModel: StatusView.ViewModel?
        @Published public var quoteViewModel: StatusView.ViewModel?
        
        // input
        public let kind: Kind
        public weak var delegate: StatusViewDelegate?
        
        weak var parentViewModel: StatusView.ViewModel?
        @Published public var authorAvatarDimension: CGFloat = .zero
        
        // output
        
        // header
        @Published public var statusHeaderViewModel: StatusHeaderView.ViewModel?

        // author
        @Published public var avatarURL: URL?
        @Published public var authorName: MetaContent = PlaintextMetaContent(string: "")
        @Published public var authorUsernme = ""
        
//        static let pollOptionOrdinalNumberFormatter: NumberFormatter = {
//            let formatter = NumberFormatter()
//            formatter.numberStyle = .ordinal
//            return formatter
//        }()
//
//        var disposeBag = Set<AnyCancellable>()
//        var observations = Set<NSKeyValueObservation>()
//        var objects = Set<NSManagedObject>()

//        @Published public var platform: Platform = .none
//        @Published public var authenticationContext: AuthenticationContext?       // me
//        @Published public var managedObjectContext: NSManagedObjectContext?
//
//        @Published public var header: Header = .none
//
//        @Published public var userIdentifier: UserIdentifier?
//        @Published public var authorAvatarImage: UIImage?
//        @Published public var authorAvatarImageURL: URL?
//        @Published public var authorUsername: String?
//        
//        @Published public var protected: Bool = false
//
//        @Published public var isMyself = false
//
        @Published public var spoilerContent: MetaContent = PlaintextMetaContent(string: "")
        @Published public var content: MetaContent = PlaintextMetaContent(string: "")
        
//        @Published public var twitterTextProvider: TwitterTextProvider?
//        
//        @Published public var language: String?
//        @Published public var isTranslateButtonDisplay = false
//
        @Published public var mediaViewModels: [MediaView.ViewModel] = []
//        @Published public var mediaViewConfigurations: [MediaView.Configuration] = []
//        
//        @Published public var isContentSensitive: Bool = false
//        @Published public var isContentSensitiveToggled: Bool = false
//        
//        @Published public var isContentReveal: Bool = false
//        
//        @Published public var isMediaSensitive: Bool = false
//        @Published public var isMediaSensitiveToggled: Bool = false
//            
//        @Published public var isMediaSensitiveSwitchable = false
//        @Published public var isMediaReveal: Bool = false
//        
//        // poll input
//        @Published public var pollItems: [PollItem] = []
//        @Published public var isVotable: Bool = false
//        @Published public var isVoting: Bool = false
//        @Published public var isVoteButtonEnabled: Bool = false
//        @Published public var voterCount: Int?
//        @Published public var voteCount = 0
//        @Published public var expireAt: Date?
//        @Published public var expired: Bool = false
//        
//        // poll output
//        @Published public var pollVoteDescription = ""
//        @Published public var pollCountdownDescription: String?
//        
//        @Published public var location: String?
//        @Published public var source: String?
//        
//        @Published public var isRepost = false
//        @Published public var isRepostEnabled = true
//        
//        @Published public var isLike = false
//        
//        @Published public var replyCount: Int = 0
//        @Published public var repostCount: Int = 0
//        @Published public var quoteCount: Int = 0
//        @Published public var likeCount: Int = 0
//        
//        @Published public var visibility: StatusVisibility?
//        @Published public var replySettings: Twitter.Entity.V2.Tweet.ReplySettings?
//        
//        @Published public var dateTimeProvider: DateTimeProvider?
//        @Published public var timestamp: Date?
//        @Published public var timeAgoStyleTimestamp: String?
//        @Published public var formattedStyleTimestamp: String?
//        
//        @Published public var sharePlaintextContent: String?
//        @Published public var shareStatusURL: String?
//        
//        @Published public var isDeletable = false
//        
//        @Published public var groupedAccessibilityLabel = ""
//
        @Published public var timestampLabelViewModel: TimestampLabelView.ViewModel?
        
//        
//        // public let contentRevealChangePublisher = PassthroughSubject<Void, Never>()
//        
        public enum Header {
            case none
            case repost(info: RepostInfo)
            case notification(info: NotificationHeaderInfo)
            // TODO: replyTo
            
            public struct RepostInfo {
                public let authorNameMetaContent: MetaContent
            }
        }
        
//        public func prepareForReuse() {
//            replySettings = nil
//        }
//        
        init(
            kind: Kind,
            delegate: StatusViewDelegate?,
            viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
        ) {
            self.kind = kind
            self.delegate = delegate
            // end init
            
            viewLayoutFramePublisher?.assign(to: &$viewLayoutFrame)
            
//            // isMyself
//            Publishers.CombineLatest(
//                $authenticationContext,
//                $userIdentifier
//            )
//            .map { authenticationContext, userIdentifier in
//                guard let authenticationContext = authenticationContext,
//                      let userIdentifier = userIdentifier
//                else { return false }
//                return authenticationContext.userIdentifier == userIdentifier
//            }
//            .assign(to: &$isMyself)
//            // isContentSensitive
//            Publishers.CombineLatest(
//                $platform,
//                $spoilerContent
//            )
//            .map { platform, spoilerContent in
//                switch platform {
//                case .none:         return false
//                case .twitter:      return false
//                case .mastodon:     return spoilerContent != nil
//                }
//            }
//            .assign(to: &$isContentSensitive)
//            // isContentReveal
//            Publishers.CombineLatest(
//                $isContentSensitive,
//                $isContentSensitiveToggled
//            )
//            .map { $0 ? $1 : !$1 }
//            .assign(to: &$isContentReveal)
//            // isMediaReveal
//            Publishers.CombineLatest(
//                $isMediaSensitive,
//                $isMediaSensitiveToggled
//            )
//            .map { $0 ? $1 : !$1 }
//            .assign(to: &$isMediaReveal)
//            // isRepostEnabled
//            Publishers.CombineLatest4(
//                $platform,
//                $visibility,
//                $protected,
//                $isMyself
//            )
//            .map { platform, visibility, protected, isMyself in
//                switch platform {
//                case .none:
//                    return true
//                case .twitter:
//                    return isMyself ? true : !protected
//                case .mastodon:
//                    if isMyself {
//                        return true
//                    }
//                    switch visibility {
//                    case .none:
//                        return true
//                    case .mastodon(let visibility):
//                        switch visibility {
//                        case .public, .unlisted:
//                            return true
//                        case .private, .direct, ._other:
//                            return false
//                        }
//                    }
//                }
//            }
//            .assign(to: &$isRepostEnabled)
//            
//            Publishers.CombineLatest(
//                UserDefaults.shared.publisher(for: \.translateButtonPreference),
//                $language
//            )
//            .map { preference, language -> Bool in
//                switch preference {
//                case .auto:
//                    guard let language = language, !language.isEmpty else {
//                        // default hidden
//                        return false
//                    }
//                    let contentLocale = Locale(identifier: language)
//                    guard let currentLanguageCode = Locale.current.languageCode,
//                          let contentLanguageCode = contentLocale.languageCode
//                    else { return true }
//                    return currentLanguageCode != contentLanguageCode
//                case .always:   return true
//                case .off:      return false
//                }
//            }
//            .assign(to: &$isTranslateButtonDisplay)
        }
    }
}

//extension StatusView.ViewModel {
//    func bind(statusView: StatusView) {
//        bindHeader(statusView: statusView)
//        bindAuthor(statusView: statusView)
//        bindContent(statusView: statusView)
//        bindMedia(statusView: statusView)
//        bindPoll(statusView: statusView)
//        bindLocation(statusView: statusView)
//        bindToolbar(statusView: statusView)
//        bindReplySettings(statusView: statusView)
//        bindAccessibility(statusView: statusView)
//    }
//    
//    private func bindHeader(statusView: StatusView) {
//        $header
//            .sink { header in
//                switch header {
//                case .none:
//                    return
//                case .repost(let info):
//                    statusView.headerIconImageView.image = Asset.Media.repeat.image
//                    statusView.headerIconImageView.tintColor = Asset.Colors.Theme.daylight.color
//                    statusView.headerTextLabel.setupAttributes(style: StatusView.headerTextLabelStyle)
//                    statusView.headerTextLabel.configure(content: info.authorNameMetaContent)
//                    statusView.setHeaderDisplay()
//                case .notification(let info):
//                    statusView.headerIconImageView.image = info.iconImage
//                    statusView.headerIconImageView.tintColor = info.iconImageTintColor
//                    statusView.headerTextLabel.setupAttributes(style: StatusView.headerTextLabelStyle)
//                    statusView.headerTextLabel.configure(content: info.textMetaContent)
//                    statusView.setHeaderDisplay()
//                }
//            }
//            .store(in: &disposeBag)
//    }
//    
//    private func bindAuthor(statusView: StatusView) {
//        // avatar
//        Publishers.CombineLatest(
//            $authorAvatarImage,
//            $authorAvatarImageURL
//        )
//        .sink { image, url in
//            let configuration: AvatarImageView.Configuration = {
//                if let image = image {
//                    return AvatarImageView.Configuration(image: image)
//                } else {
//                    return AvatarImageView.Configuration(url: url)
//                }
//            }()
//            statusView.authorAvatarButton.avatarImageView.configure(configuration: configuration)
//        }
//        .store(in: &disposeBag)
//        UserDefaults.shared
//            .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
//                
//                let avatarStyle = defaults.avatarStyle
//                let animator = UIViewPropertyAnimator(duration: 0.3, timingParameters: UISpringTimingParameters())
//                animator.addAnimations {
//                    switch avatarStyle {
//                    case .circle:
//                        statusView.authorAvatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .circle))
//                    case .roundedSquare:
//                        statusView.authorAvatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .scale(ratio: 4)))
//                    }
//                }
//                animator.startAnimation()
//            }
//            .store(in: &observations)
//        // lock
//        $protected
//            .sink { protected in
//                statusView.lockImageView.isHidden = !protected
//            }
//            .store(in: &disposeBag)
//        // name
//        $authorName
//            .sink { metaContent in
//                let metaContent = metaContent ?? PlaintextMetaContent(string: "")
//                statusView.authorNameLabel.setupAttributes(style: StatusView.authorNameLabelStyle)
//                statusView.authorNameLabel.configure(content: metaContent)
//            }
//            .store(in: &disposeBag)
//        // username
//        $authorUsername
//            .map { text in
//                guard let text = text else { return "" }
//                return "@\(text)"
//            }
//            .assign(to: \.text, on: statusView.authorUsernameLabel)
//            .store(in: &disposeBag)
//        // visibility
//        $visibility
//            .sink { visibility in
//                guard let visibility = visibility,
//                      let image = visibility.inlineImage
//                else { return }
//                
//                statusView.visibilityImageView.image = image
//                statusView.visibilityImageView.accessibilityLabel = visibility.accessibilityLabel
//                statusView.visibilityImageView.accessibilityTraits = .staticText
//                statusView.visibilityImageView.isAccessibilityElement = true
//                statusView.setVisibilityDisplay()
//            }
//            .store(in: &disposeBag)
//        // timestamp
//        Publishers.CombineLatest3(
//            $timestamp,
//            $dateTimeProvider,
//            timestampUpdatePublisher.prepend(Date()).eraseToAnyPublisher()
//        )
//        .sink { [weak self] timestamp, dateTimeProvider, _ in
//            guard let self = self else { return }
//            self.timeAgoStyleTimestamp = dateTimeProvider?.shortTimeAgoSinceNow(to: timestamp)
//            self.formattedStyleTimestamp = {
//                let formatter = DateFormatter()
//                formatter.dateStyle = .medium
//                formatter.timeStyle = .medium
//                let text = timestamp.flatMap { formatter.string(from: $0) }
//                return text
//            }()
//        }
//        .store(in: &disposeBag)
//        $timeAgoStyleTimestamp
//            .sink { timestamp in
//                statusView.timestampLabel.text = timestamp
//            }
//            .store(in: &disposeBag)
//        $formattedStyleTimestamp
//            .sink { timestamp in
//                statusView.metricsDashboardView.timestampLabel.text = timestamp
//            }
//            .store(in: &disposeBag)
//    }
//    
//    private func bindContent(statusView: StatusView) {
//        $content
//            .sink { metaContent in
//                guard let content = metaContent else {
//                    statusView.contentTextView.reset()
//                    return
//                }
//                statusView.contentTextView.configure(content: content)
//            }
//            .store(in: &disposeBag)
//        $spoilerContent
//            .sink { metaContent in
//                guard let metaContent = metaContent else {
//                    statusView.spoilerContentTextView.reset()
//                    return
//                }
//                statusView.spoilerContentTextView.configure(content: metaContent)
//                statusView.setSpoilerDisplay()
//            }
//            .store(in: &disposeBag)
//        $isContentReveal
//            .sink { isContentReveal in
//                statusView.contentTextView.isHidden = !isContentReveal
//                
//                let label = isContentReveal ? L10n.Accessibility.Common.Status.Actions.hideContent : L10n.Accessibility.Common.Status.Actions.revealContent
//                statusView.expandContentButton.accessibilityLabel = label
//            }
//            .store(in: &disposeBag)
//        $isTranslateButtonDisplay
//            .sink { isTranslateButtonDisplay in
//                if isTranslateButtonDisplay {
//                    statusView.setTranslateButtonDisplay()
//                }
//            }
//            .store(in: &disposeBag)
//        $source
//            .sink { source in
//                statusView.metricsDashboardView.sourceLabel.text = source ?? ""
//            }
//            .store(in: &disposeBag)
//        // dashboard
//        $platform
//            .assign(to: \.platform, on: statusView.metricsDashboardView.viewModel)
//            .store(in: &disposeBag)
//        Publishers.CombineLatest4(
//            $replyCount,
//            $repostCount,
//            $quoteCount,
//            $likeCount
//        )
//        .sink { replyCount, repostCount, quoteCount, likeCount in
//            switch statusView.style {
//            case .plain:
//                statusView.metricsDashboardView.viewModel.replyCount = replyCount
//                statusView.metricsDashboardView.viewModel.repostCount = repostCount
//                statusView.metricsDashboardView.viewModel.quoteCount = quoteCount
//                statusView.metricsDashboardView.viewModel.likeCount = likeCount
//            default:
//                break
//            }
//        }
//        .store(in: &disposeBag)
//    }
//    
//    private func bindMedia(statusView: StatusView) {
//        $mediaViewConfigurations
//            .sink { [weak self] configurations in
//                guard let self = self else { return }
//                // self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): configure media")
//                
//                let maxSize = CGSize(
//                    width: statusView.contentMaxLayoutWidth,
//                    height: statusView.contentMaxLayoutWidth
//                )
//                var needsDisplay = true
//                switch configurations.count {
//                case 0:
//                    needsDisplay = false
//                case 1:
//                    let configuration = configurations[0]
//                    let adaptiveLayout = MediaGridContainerView.AdaptiveLayout(
//                        aspectRatio: configuration.aspectRadio,
//                        maxSize: maxSize
//                    )
//                    let mediaView = statusView.mediaGridContainerView.dequeueMediaView(adaptiveLayout: adaptiveLayout)
//                    mediaView.setup(configuration: configuration)
//                default:
//                    let gridLayout = MediaGridContainerView.GridLayout(
//                        count: configurations.count,
//                        maxSize: maxSize
//                    )
//                    let mediaViews = statusView.mediaGridContainerView.dequeueMediaView(gridLayout: gridLayout)
//                    for (i, (configuration, mediaView)) in zip(configurations, mediaViews).enumerated() {
//                        guard i < MediaGridContainerView.maxCount else { break }
//                        mediaView.setup(configuration: configuration)
//                    }
//                }
//                if needsDisplay {
//                    statusView.setMediaDisplay()
//                }
//            }
//            .store(in: &disposeBag)
//        $isMediaReveal
//            .sink { isMediaReveal in
//                statusView.mediaGridContainerView.viewModel.isContentWarningOverlayDisplay = !isMediaReveal
//            }
//            .store(in: &disposeBag)
//        $isMediaSensitiveSwitchable
//            .sink { isMediaSensitiveSwitchable in
//                statusView.mediaGridContainerView.viewModel.isSensitiveToggleButtonDisplay = isMediaSensitiveSwitchable
//            }
//            .store(in: &disposeBag)
//    }
//    
//    private func bindPoll(statusView: StatusView) {
//        $pollItems
//            .sink { items in
//                guard !items.isEmpty else { return }
//                
//                var snapshot = NSDiffableDataSourceSnapshot<PollSection, PollItem>()
//                snapshot.appendSections([.main])
//                snapshot.appendItems(items, toSection: .main)
//                statusView.pollTableViewDiffableDataSource?.applySnapshotUsingReloadData(snapshot)
//                
//                statusView.pollTableViewHeightLayoutConstraint.constant = CGFloat(items.count) * PollOptionTableViewCell.height
//                statusView.setPollDisplay()
//            }
//            .store(in: &disposeBag)
//        $isVotable
//            .sink { isVotable in
//                statusView.pollTableView.allowsSelection = isVotable
//            }
//            .store(in: &disposeBag)
//        // poll
//        Publishers.CombineLatest(
//            $voterCount,
//            $voteCount
//        )
//        .map { voterCount, voteCount -> String in
//            var description = ""
//            if let voterCount = voterCount {
//                description += L10n.Count.people(voterCount)
//            } else {
//                description += L10n.Count.vote(voteCount)
//            }
//            return description
//        }
//        .assign(to: &$pollVoteDescription)
//        Publishers.CombineLatest3(
//            $expireAt,
//            $expired,
//            timestampUpdatePublisher.prepend(Date()).eraseToAnyPublisher()
//        )
//        .map { expireAt, expired, _ -> String? in
//            guard !expired else {
//                return L10n.Common.Controls.Status.Poll.expired
//            }
//            
//            guard let expireAt = expireAt,
//                  let timeLeft = expireAt.localizedTimeLeft
//            else {
//                return nil
//            }
//            
//            return timeLeft
//        }
//        .assign(to: &$pollCountdownDescription)
//        Publishers.CombineLatest(
//            $pollVoteDescription,
//            $pollCountdownDescription
//        )
//        .sink { pollVoteDescription, pollCountdownDescription in
//            let description = [
//                pollVoteDescription,
//                pollCountdownDescription
//            ]
//            .compactMap { $0 }
//            
//            statusView.pollVoteDescriptionLabel.text = description.joined(separator: " · ")
//            statusView.pollVoteDescriptionLabel.accessibilityLabel = description.joined(separator: ", ")
//        }
//        .store(in: &disposeBag)
//        Publishers.CombineLatest(
//            $isVotable,
//            $isVoting
//        )
//        .sink { isVotable, isVoting in
//            guard isVotable else {
//                statusView.pollVoteButton.isHidden = true
//                statusView.pollVoteActivityIndicatorView.isHidden = true
//                return
//            }
//            
//            statusView.pollVoteButton.isHidden = isVoting
//            statusView.pollVoteActivityIndicatorView.isHidden = !isVoting
//            statusView.pollVoteActivityIndicatorView.startAnimating()
//        }
//        .store(in: &disposeBag)
//        $isVoteButtonEnabled
//            .assign(to: \.isEnabled, on: statusView.pollVoteButton)
//            .store(in: &disposeBag)
//    }
//    
//    private func bindLocation(statusView: StatusView) {
//        $location
//            .sink { location in
//                guard let location = location, !location.isEmpty else {
//                    statusView.locationLabel.isAccessibilityElement = false
//                    return
//                }
//                statusView.locationLabel.isAccessibilityElement = true
//                
//                if statusView.traitCollection.preferredContentSizeCategory > .extraLarge {
//                    statusView.locationMapPinImageView.image = Asset.ObjectTools.mappin.image
//                } else {
//                    statusView.locationMapPinImageView.image = Asset.ObjectTools.mappinMini.image
//                }
//                statusView.locationLabel.text = location
//                statusView.locationLabel.accessibilityLabel = location
//                
//                statusView.setLocationDisplay()
//            }
//            .store(in: &disposeBag)
//    }
//    
//    private func bindToolbar(statusView: StatusView) {
//        // platform
//        $platform
//            .assign(to: \.platform, on: statusView.toolbar.viewModel)
//            .store(in: &disposeBag)
//        // reply
//        $replyCount
//            .sink { count in
//                statusView.toolbar.setupReply(count: count, isEnabled: true)    // TODO:
//            }
//            .store(in: &disposeBag)
//        // repost
//        Publishers.CombineLatest3(
//            $repostCount,
//            $isRepost,
//            $isRepostEnabled
//        )
//        .sink { count, isRepost, isEnabled in
//            statusView.toolbar.setupRepost(count: count, isEnabled: isEnabled, isHighlighted: isRepost)
//        }
//        .store(in: &disposeBag)
//        // like
//        Publishers.CombineLatest(
//            $likeCount,
//            $isLike
//        )
//        .sink { count, isLike in
//            statusView.toolbar.setupLike(count: count, isHighlighted: isLike)
//        }
//        .store(in: &disposeBag)
//        // menu
//        Publishers.CombineLatest4(
//            $sharePlaintextContent,
//            $shareStatusURL,
//            $mediaViewConfigurations,
//            $isDeletable
//        )
//        .sink { sharePlaintextContent, shareStatusURL, mediaViewConfigurations, isDeletable in
//            statusView.toolbar.setupMenu(menuContext: .init(
//                shareText: sharePlaintextContent,
//                shareLink: shareStatusURL,
//                displaySaveMediaAction: !mediaViewConfigurations.isEmpty,
//                displayDeleteAction: isDeletable
//            ))
//        }
//        .store(in: &disposeBag)
//    }
//    
//    private func bindReplySettings(statusView: StatusView) {
//        Publishers.CombineLatest(
//            $replySettings,
//            $authorUsername
//        )
//        .sink { replySettings, authorUsername in
//            guard let replySettings = replySettings else { return }
//            guard let authorUsername = authorUsername else { return }
//            switch replySettings {
//            case .everyone:
//                return
//            case .following:
//                statusView.replySettingBannerView.imageView.image = Asset.Communication.at.image.withRenderingMode(.alwaysTemplate)
//                statusView.replySettingBannerView.label.text = L10n.Common.Controls.Status.ReplySettings.peopleUserFollowsOrMentionedCanReply("@\(authorUsername)")
//            case .mentionedUsers:
//                statusView.replySettingBannerView.imageView.image = Asset.Human.personCheckMini.image.withRenderingMode(.alwaysTemplate)
//                statusView.replySettingBannerView.label.text = L10n.Common.Controls.Status.ReplySettings.peopleUserMentionedCanReply("@\(authorUsername)")
//            }
//            statusView.setReplySettingsDisplay()
//        }
//        .store(in: &disposeBag)
//    }
//    
//    private func bindAccessibility(statusView: StatusView) {
//        let authorAccessibilityLabel = Publishers.CombineLatest(
//            $header,
//            $authorName
//        )
//        .map { header, authorName -> String? in
//            var strings: [String?] = []
//            
//            switch header {
//            case .none:
//                break
//            case .notification(let info):
//                strings.append(info.textMetaContent.string)
//            case .repost(let info):
//                strings.append(info.authorNameMetaContent.string)
//            }
//            
//            strings.append(authorName?.string)
//            
//            return strings.compactMap { $0 }.joined(separator: ", ")
//        }
//        
//        let metaAccessibilityLabel = Publishers.CombineLatest(
//            $timeAgoStyleTimestamp,
//            $visibility
//        )
//        .map { timestamp, visibility -> String? in
//            var strings: [String?] = []
//            
//            strings.append(visibility?.accessibilityLabel)
//            strings.append(timestamp)
//            
//            return strings.compactMap { $0 }.joined(separator: ", ")
//        }
//        
//        let contentAccessibilityLabel = Publishers.CombineLatest4(
//            $platform,
//            $isContentReveal,
//            $spoilerContent,
//            $content
//        )
//        .map { platform, isContentReveal, spoilerContent, content -> String? in
//            var strings: [String?] = []
//            switch platform {
//            case .none:
//                break
//            case .twitter:
//                strings.append(content?.string)
//            case .mastodon:
//                if let spoilerContent = spoilerContent?.string {
//                    strings.append(L10n.Accessibility.Common.Status.contentWarning)
//                    strings.append(spoilerContent)
//                }
//                if isContentReveal {
//                    strings.append(content?.string)
//                }
//            }
//            
//            return strings.compactMap { $0 }.joined(separator: ", ")
//        }
//        
//        let mediaAccessibilityLabel = $mediaViewConfigurations
//            .map { configurations -> String? in
//                let count = configurations.count
//                return count > 0 ? L10n.Count.media(count) : nil
//            }
//        
//        let toolbarAccessibilityLabel = Publishers.CombineLatest3(
//            $platform,
//            $isRepost,
//            $isLike
//        )
//        .map { platform, isRepost, isLike -> String? in
//            var strings: [String?] = []
//            
//            switch platform {
//            case .none:
//                break
//            case .twitter:
//                if isRepost {
//                    strings.append(L10n.Accessibility.Common.Status.retweeted)
//                }
//            case .mastodon:
//                if isRepost {
//                    strings.append(L10n.Accessibility.Common.Status.boosted)
//                }
//            }
//            
//            if isLike {
//                strings.append(L10n.Accessibility.Common.Status.liked)
//            }
//            
//            return strings.compactMap { $0 }.joined(separator: ", ")
//        }
//        
//        let pollAccessibilityLabel = Publishers.CombineLatest3(
//                $pollItems,
//                $pollVoteDescription,
//                $pollCountdownDescription
//            )
//            .map { items, pollVoteDescription, pollCountdownDescription -> String? in
//                guard !items.isEmpty else { return nil }
//                guard let managedObjectContext = self.managedObjectContext else { return nil }
//                
//                var strings: [String?] = []
//                
//                let ordinalPrefix = L10n.Accessibility.Common.Status.pollOptionOrdinalPrefix
//                
//                for (i, item) in items.enumerated() {
//                    switch item {
//                    case .option(let record):
//                        guard let option = record.object(in: managedObjectContext) else { continue }
//                        let number = NSNumber(value: i + 1)
//                        guard let ordinal = StatusView.ViewModel.pollOptionOrdinalNumberFormatter.string(from: number) else { break }
//                        strings.append("\(ordinalPrefix), \(ordinal), \(option.title)")
//                        
//                        if option.isSelected {
//                            strings.append(L10n.Accessibility.VoiceOver.selected)
//                        }
//                    }
//                }
//                
//                strings.append(pollVoteDescription)
//                pollCountdownDescription.flatMap { strings.append($0) }
//                
//                return strings.compactMap { $0 }.joined(separator: ", ")
//            }
//        
//        let groupOne = Publishers.CombineLatest4(
//            authorAccessibilityLabel,
//            metaAccessibilityLabel,
//            contentAccessibilityLabel,
//            mediaAccessibilityLabel
//        )
//        .map { a, b, c, d -> String? in
//            return [a, b, c, d]
//                .compactMap { $0 }
//                .joined(separator: ", ")
//        }
//        
//        let groupTwo = Publishers.CombineLatest3(
//            pollAccessibilityLabel,
//            $location,
//            toolbarAccessibilityLabel
//        )
//        .map { a, b, c -> String? in
//            return [a, b, c]
//                .compactMap { $0 }
//                .joined(separator: ", ")
//        }
//            
//        Publishers.CombineLatest(
//            groupOne,
//            groupTwo
//        )
//        .map { a, b -> String in
//            return [a, b]
//                .compactMap { $0 }
//                .joined(separator: ", ")
//        }
//        .assign(to: &$groupedAccessibilityLabel)
//        
//        $groupedAccessibilityLabel
//            .sink { accessibilityLabel in
//                statusView.accessibilityLabel = accessibilityLabel
//            }
//            .store(in: &disposeBag)
//        
//        // poll
//        $pollItems
//            .sink { items in
//                statusView.pollVoteDescriptionLabel.isAccessibilityElement = !items.isEmpty
//                statusView.pollVoteButton.isAccessibilityElement = !items.isEmpty
//            }
//            .store(in: &disposeBag)
//    }
//
//}

extension StatusView.ViewModel {
    public enum Kind {
        case timeline
        case repost
        case quote
        case reference
        case conversationRoot
        case conversationThread
    }
}

extension StatusView.ViewModel {
    var hasHangingAvatar: Bool {
        switch kind {
        case .conversationRoot, .quote:
            return false
        default:
            return true
        }
    }
    
    public var margin: CGFloat {
        switch kind {
        case .quote:
            return 12
        default:
            return .zero
        }
    }
    
    public var hasToolbar: Bool {
        switch kind {
        case .timeline, .conversationRoot, .conversationThread:
            return true
        default:
            return false
        }
    }
}

extension StatusView.ViewModel {
    public convenience init?(
        feed: Feed,
        delegate: StatusViewDelegate?,
        viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
    ) {
        switch feed.content {
        case .twitter(let status):
            self.init(
                status: status,
                kind: .timeline,
                delegate: delegate,
                parentViewModel: nil,
                viewLayoutFramePublisher: viewLayoutFramePublisher
            )
        case .mastodon(let status):
            self.init(
                status: status,
                kind: .timeline,
                delegate: delegate,
                parentViewModel: nil,
                viewLayoutFramePublisher: viewLayoutFramePublisher
            )
        case .mastodonNotification(let notification):
            return nil
        case .none:
            return nil
        }
    }
}
 
extension StatusView.ViewModel {
    public convenience init(
        status: TwitterStatus,
        kind: Kind,
        delegate: StatusViewDelegate?,
        parentViewModel: StatusView.ViewModel?,
        viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
    ) {
        self.init(
            kind: kind,
            delegate: delegate,
            viewLayoutFramePublisher: viewLayoutFramePublisher
        )
        self.parentViewModel = parentViewModel
        
        if let repost = status.repost {
            let _repostViewModel = StatusView.ViewModel(
                status: repost,
                kind: .repost,
                delegate: delegate,
                parentViewModel: self,
                viewLayoutFramePublisher: viewLayoutFramePublisher
            )
            repostViewModel = _repostViewModel
            
            // header - repost
            let _statusHeaderViewModel = StatusHeaderView.ViewModel(
                image: Asset.Media.repeat.image.withRenderingMode(.alwaysTemplate),
                label: {
                    let name = status.author.name
                    let userRepostText = L10n.Common.Controls.Status.userRetweeted(name)
                    let label = PlaintextMetaContent(string: userRepostText)
                    return label
                }()
            )
            _statusHeaderViewModel.hasHangingAvatar = _repostViewModel.hasHangingAvatar
            _repostViewModel.statusHeaderViewModel = _statusHeaderViewModel
        }
        if let quote = status.quote {
            quoteViewModel = .init(
                status: quote,
                kind: .quote,
                delegate: delegate,
                parentViewModel: self,
                viewLayoutFramePublisher: viewLayoutFramePublisher
            )
        }

        // author
        status.author.publisher(for: \.profileImageURL)
            .map { _ in status.author.avatarImageURL() }
            .assign(to: &$avatarURL)
        status.author.publisher(for: \.name)
            .map { PlaintextMetaContent(string: $0) }
            .assign(to: &$authorName)
        status.author.publisher(for: \.username)
            .assign(to: &$authorUsernme)
        
        // timestamp
        switch kind {
        case .timeline, .repost:
            timestampLabelViewModel = TimestampLabelView.ViewModel(timestamp: status.createdAt)
        default:
            break
        }
        
        // content
        let content = TwitterContent(content: status.displayText)
        let metaContent = TwitterMetaContent.convert(
            content: content,
            urlMaximumLength: 20,
            twitterTextProvider: SwiftTwitterTextProvider(),
            useParagraphMark: true
        )
        self.content = metaContent
        
        // media
        mediaViewModels = MediaView.ViewModel.viewModels(from: status)
    }   // end init
}

extension StatusView.ViewModel {
    public convenience init(
        status: MastodonStatus,
        kind: Kind,
        delegate: StatusViewDelegate?,
        parentViewModel: StatusView.ViewModel?,
        viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
    ) {
        self.init(
            kind: kind,
            delegate: delegate,
            viewLayoutFramePublisher: viewLayoutFramePublisher
        )
        self.parentViewModel = parentViewModel
        
        if let repost = status.repost {
            repostViewModel = .init(
                status: repost,
                kind: .repost,
                delegate: delegate,
                parentViewModel: self,
                viewLayoutFramePublisher: viewLayoutFramePublisher
            )
        }
        
        status.author.publisher(for: \.avatar)
            .compactMap { $0.flatMap { URL(string: $0) } }
            .assign(to: &$avatarURL)
        status.author.publisher(for: \.displayName)
            .compactMap { _ in status.author.nameMetaContent }
            .assign(to: &$authorName)
        status.author.publisher(for: \.username)
            .assign(to: &$authorUsernme)
        
        do {
            let content = MastodonContent(content: status.content, emojis: status.emojis.asDictionary)
            let metaContent = try MastodonMetaContent.convert(document: content, useParagraphMark: true)
            self.content = metaContent
            // viewModel.sharePlaintextContent = metaContent.original
        } catch {
            assertionFailure(error.localizedDescription)
            self.content = PlaintextMetaContent(string: "")
        }
    }
}
