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
        public let status: StatusObject?
        public let author: UserObject?
        public let authContext: AuthContext?
        public let kind: Kind
        public weak var delegate: StatusViewDelegate?
        
        weak var parentViewModel: StatusView.ViewModel?
        
        @Published public var addtionalHorizontalMargin: CGFloat = 0.0
        
        // output
        
        // header
        @Published public var statusHeaderViewModel: StatusHeaderView.ViewModel?

        // author
        @Published public var avatarURL: URL?
        @Published public var avatarStyle = UserDefaults.shared.avatarStyle
        
        @Published public var authorName: MetaContent = PlaintextMetaContent(string: "")
        @Published public var authorUsernme = ""
        @Published public var authorUserIdentifier: UserIdentifier?
        
//        static let pollOptionOrdinalNumberFormatter: NumberFormatter = {
//            let formatter = NumberFormatter()
//            formatter.numberStyle = .ordinal
//            return formatter
//        }()
//
//        @Published public var userIdentifier: UserIdentifier?
//        @Published public var authorAvatarImage: UIImage?
//        @Published public var authorAvatarImageURL: URL?
//        @Published public var authorUsername: String?
//        
//        @Published public var protected: Bool = false

        // content
        @Published public var spoilerContent: MetaContent?
        @Published public var content: MetaContent = PlaintextMetaContent(string: "")
        
        var isContentEmpty: Bool { content.string.isEmpty }
        var isContentSensitive: Bool { spoilerContent != nil }
        @Published public var isContentSensitiveToggled: Bool = false
        public var isContentReveal: Bool {
            return isContentSensitive ? isContentSensitiveToggled : !isContentEmpty
        }

        // language
        @Published public var language: String?
        @Published public private(set) var translateButtonPreference: UserDefaults.TranslateButtonPreference?
        public var isTranslateButtonDisplay: Bool {
            // only display for conversation root
            switch kind {
            case .conversationRoot:     break
            default:                    return false
            }
            // check prefernece and compare device language
            switch translateButtonPreference {
            case .auto:
                guard let language = language, !language.isEmpty else {
                    // default hidden
                    return false
                }
                let contentLocale = Locale(identifier: language)
                guard let currentLanguageCode = Locale.current.language.languageCode?.identifier,
                      let contentLanguageCode = contentLocale.language.languageCode?.identifier
                else { return true }
                return currentLanguageCode != contentLanguageCode
            case .always:   return true
            case .off:      return false
            case nil:       return false
            }
        }

        // media
        @Published public var mediaViewModels: [MediaView.ViewModel] = []
        @Published public var isMediaSensitive: Bool = false
        @Published public var isMediaSensitiveToggled: Bool = false
        public var isMediaContentWarningOverlayReveal: Bool {
            return isMediaSensitiveToggled ? isMediaSensitive : !isMediaSensitive
        }


//        @Published public var isRepost = false
//        @Published public var isRepostEnabled = true
        
        // poll
        @Published public var pollViewModel: PollView.ViewModel?

        // visibility
        @Published public var visibility: MastodonVisibility?
        var visibilityIconImage: UIImage? {
            switch visibility {
            case .public:
                return Asset.ObjectTools.globeMiniInline.image.withRenderingMode(.alwaysTemplate)
            case .unlisted:
                return Asset.ObjectTools.lockOpenMiniInline.image.withRenderingMode(.alwaysTemplate)
            case .private:
                return Asset.ObjectTools.lockMiniInline.image.withRenderingMode(.alwaysTemplate)
            case .direct:
                return Asset.Communication.mailMiniInline.image.withRenderingMode(.alwaysTemplate)
            case ._other:
                assertionFailure()
                return nil
            case nil:
                return nil
            }
        }
//        @Published public var replySettings: Twitter.Entity.V2.Tweet.ReplySettings?

//////
//        @Published public var groupedAccessibilityLabel = ""

        // timestamp
        @Published public var timestampLabelViewModel: TimestampLabelView.ViewModel?
        
        // location
        @Published public var location: String?
        
        // metric
        @Published public var metricViewModel: StatusMetricView.ViewModel?

        // toolbar
        public let toolbarViewModel = StatusToolbarView.ViewModel()
        public var canDelete: Bool {
            guard let authContext = self.authContext else { return false }
            guard let authorUserIdentifier = self.authorUserIdentifier else { return false }
            return authContext.authenticationContext.userIdentifier == authorUserIdentifier
        }

        // conversation link
        @Published public var isTopConversationLinkLineViewDisplay = false
        @Published public var isBottomConversationLinkLineViewDisplay = false
        
        private init(
            status: StatusObject,
            author: UserObject,
            authContext: AuthContext?,
            kind: Kind,
            delegate: StatusViewDelegate?,
            viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
        ) {
            self.status = status
            self.author = author
            self.authContext = authContext
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

            setupBinding()
        }
        
        private init(
             viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
        ) {
            self.status = nil
            self.author = nil
            self.authContext = nil
            self.kind = .timeline
            // end init
            
            viewLayoutFramePublisher?.assign(to: &$viewLayoutFrame)
            
            setupBinding()
        }
        
        private func setupBinding() {
            // avatar style
            UserDefaults.shared.publisher(for: \.avatarStyle)
                .assign(to: &$avatarStyle)
            
            // translate button
            UserDefaults.shared.publisher(for: \.translateButtonPreference)
                .map { $0 }
                .assign(to: &$translateButtonPreference)

            // toolbar
            toolbarViewModel.style = kind == .conversationRoot ? .plain : .inline
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
        case referenceReplyTo
        case referenceQuote
        case conversationRoot
        case conversationThread
    }
}

extension StatusView.ViewModel {
    var contentWidth: CGFloat {
        let width = containerWidth - 2 * margin
        return max(width, .leastNonzeroMagnitude)
    }
    
    var containerWidth: CGFloat {
        let width: CGFloat = {
            var width = parentViewModel?.containerWidth ?? (viewLayoutFrame.readableContentLayoutFrame.width - addtionalHorizontalMargin)
            width -= containerMargin
            return width
        }()
        return max(width, .leastNonzeroMagnitude)
    }
    
    var containerMargin: CGFloat {
        var width: CGFloat = 0
        switch kind {
        case .timeline, .referenceReplyTo:
            width += StatusView.hangingAvatarButtonDimension
            width += StatusView.hangingAvatarButtonTrailingSpacing
        default:
            break
        }
        return width
    }
    
    var margin: CGFloat {
        switch kind {
        case .quote:        return 12
        default:            return .zero
        }
    }
    
    var hasHangingAvatar: Bool {
        switch kind {
        case .conversationRoot, .quote:
            return false
        default:
            return true
        }
    }
    
    var cellTopMargin: CGFloat {
        return parentViewModel == nil ? 12 : 0
    }
    
    var topConversationLinkViewHeight: CGFloat {
        var height: CGFloat = cellTopMargin
        if let statusHeaderViewModel = statusHeaderViewModel {
            height += statusHeaderViewModel.viewSize.height
            height += StatusView.statusHeaderBottomSpacing
            height += parentViewModel?.cellTopMargin ?? 0
        }
        return height
    }
    
    var hasToolbar: Bool {
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
        authContext: AuthContext?,
        delegate: StatusViewDelegate?,
        viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
    ) {
        switch feed.content {
        case .status(let object):
            self.init(
                status: object,
                authContext: authContext,
                kind: .timeline,
                delegate: delegate,
                viewLayoutFramePublisher: viewLayoutFramePublisher
            )
        default:
            assertionFailure("should use other View & ViewModel")
            return nil
        }
    }   // end init
    
    public convenience init(
        status: StatusObject,
        authContext: AuthContext?,
        kind: Kind = .timeline,
        delegate: StatusViewDelegate?,
        viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
    ) {
        switch status {
        case .twitter(let status):
            self.init(
                status: status,
                authContext: authContext,
                kind: kind,
                delegate: delegate,
                parentViewModel: nil,
                viewLayoutFramePublisher: viewLayoutFramePublisher
            )
        case .mastodon(let status):
            self.init(
                status: status,
                authContext: authContext,
                kind: kind,
                delegate: delegate,
                parentViewModel: nil,
                viewLayoutFramePublisher: viewLayoutFramePublisher
            )
        }
    }   // end init
}
 
extension StatusView.ViewModel {
    public convenience init(
        status: TwitterStatus,
        authContext: AuthContext?,
        kind: Kind,
        delegate: StatusViewDelegate?,
        parentViewModel: StatusView.ViewModel?,
        viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
    ) {
        self.init(
            status: .twitter(object: status),
            author: .twitter(object: status.author),
            authContext: authContext,
            kind: status.repost != nil ? .repost : kind,
            delegate: delegate,
            viewLayoutFramePublisher: viewLayoutFramePublisher
        )
        self.parentViewModel = parentViewModel
        
        if let repost = status.repost {
            let _repostViewModel = StatusView.ViewModel(
                status: repost,
                authContext: authContext,
                kind: kind,
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
            _statusHeaderViewModel.hasHangingAvatar = {
                if kind == .conversationRoot { return true }
                return _repostViewModel.hasHangingAvatar
            }()
            _repostViewModel.statusHeaderViewModel = _statusHeaderViewModel
        }
        if let quote = status.quote {
            quoteViewModel = .init(
                status: quote,
                authContext: authContext,
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
        authorUserIdentifier = .twitter(.init(id: status.author.id))
        
        // timestamp
        switch kind {
        case .conversationRoot:
            break
        default:
            timestampLabelViewModel = TimestampLabelView.ViewModel(timestamp: status.createdAt)
        }
        
        // content
        let content = TwitterContent(content: status.displayText, urlEntities: status.urlEntities)
        let metaContent = TwitterMetaContent.convert(
            document: content,
            urlMaximumLength: .max,
            twitterTextProvider: SwiftTwitterTextProvider(),
            useParagraphMark: true
        )
        self.content = metaContent
        
        // language
        status.publisher(for: \.language)
            .map { language in
                switch language {
                case "qam", "qct", "qht", "qme", "qst", "zxx":
                    return nil
                default:
                    return language
                }
            }
            .assign(to: &$language)
        
        // media
        mediaViewModels = MediaView.ViewModel.viewModels(from: status)
        
        // poll
        if let poll = status.poll {
            self.pollViewModel = PollView.ViewModel(
                authContext: authContext,
                poll: .twitter(object: poll)
            )
        }

        // location
        location = status.location?.fullName

        // metric
        switch kind {
        case .conversationRoot:
            let _metricViewModel = StatusMetricView.ViewModel(platform: .twitter, timestamp: status.createdAt)
            metricViewModel = _metricViewModel
            status.publisher(for: \.source)
                .assign(to: &_metricViewModel.$source)
            status.publisher(for: \.replyCount)
                .map { Int($0) }
                .assign(to: &_metricViewModel.$replyCount)
            status.publisher(for: \.repostCount)
                .map { Int($0) }
                .assign(to: &_metricViewModel.$repostCount)
            status.publisher(for: \.likeCount)
                .map { Int($0) }
                .assign(to: &_metricViewModel.$likeCount)
        default:
            break
        }

        // toolbar
        toolbarViewModel.platform = .twitter
        status.publisher(for: \.replyCount)
            .map { Int($0) }
            .assign(to: &toolbarViewModel.$replyCount)
        status.publisher(for: \.repostCount)
            .map { Int($0) }
            .assign(to: &toolbarViewModel.$repostCount)
        status.publisher(for: \.likeCount)
            .map { Int($0) }
            .assign(to: &toolbarViewModel.$likeCount)
        if case let .twitter(authenticationContext) = authContext?.authenticationContext {
            status.publisher(for: \.likeBy)
                .map { users -> Bool in
                    let ids = users.map { $0.id }
                    return ids.contains(authenticationContext.userID)
                }
                .assign(to: &toolbarViewModel.$isLiked)
            status.publisher(for: \.repostBy)
                .map { users -> Bool in
                    let ids = users.map { $0.id }
                    return ids.contains(authenticationContext.userID)
                }
                .assign(to: &toolbarViewModel.$isReposted)
        } else {
            // do nothing
        }
    }   // end init
}

extension StatusView.ViewModel {
    public convenience init(
        status: MastodonStatus,
        authContext: AuthContext?,
        kind: Kind,
        delegate: StatusViewDelegate?,
        parentViewModel: StatusView.ViewModel?,
        viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
    ) {
        self.init(
            status: .mastodon(object: status),
            author: .mastodon(object: status.author),
            authContext: authContext,
            kind: status.repost != nil ? .repost : kind,
            delegate: delegate,
            viewLayoutFramePublisher: viewLayoutFramePublisher
        )
        self.parentViewModel = parentViewModel
        
        if let repost = status.repost {
            let _repostViewModel = StatusView.ViewModel(
                status: repost,
                authContext: authContext,
                kind: kind,
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
                    let userRepostText = L10n.Common.Controls.Status.userBoosted(name)
                    let text = MastodonContent(content: userRepostText, emojis: status.author.emojis.asDictionary)
                    let label = MastodonMetaContent.convert(text: text)
                    return label
                }()
            )
            _statusHeaderViewModel.hasHangingAvatar = _repostViewModel.hasHangingAvatar
            _repostViewModel.statusHeaderViewModel = _statusHeaderViewModel
        }
        
        // author
        status.author.publisher(for: \.avatar)
            .compactMap { $0.flatMap { URL(string: $0) } }
            .assign(to: &$avatarURL)
        status.author.publisher(for: \.displayName)
            .compactMap { _ in status.author.nameMetaContent }
            .assign(to: &$authorName)
        status.author.publisher(for: \.username)
            .map { _ in status.author.acct }
            .assign(to: &$authorUsernme)
        authorUserIdentifier = .mastodon(.init(domain: status.author.domain, id: status.author.id))
        
        // visibility
        visibility = status.visibility
        
        // timestamp
        switch kind {
        case .conversationRoot:
            break
        default:
            timestampLabelViewModel = TimestampLabelView.ViewModel(timestamp: status.createdAt)
        }
        
        // spoiler content
        if let spoilerText = status.spoilerText, !spoilerText.isEmpty {
            do {
                let content = MastodonContent(content: spoilerText, emojis: status.emojis.asDictionary)
                let metaContent = try MastodonMetaContent.convert(document: content, useParagraphMark: true)
                self.spoilerContent = metaContent
            } catch {
                assertionFailure(error.localizedDescription)
                self.spoilerContent = nil
            }
        }
        
        // content
        do {
            let content = MastodonContent(content: status.content, emojis: status.emojis.asDictionary)
            let metaContent = try MastodonMetaContent.convert(document: content, useParagraphMark: true)
            self.content = metaContent
        } catch {
            assertionFailure(error.localizedDescription)
            self.content = PlaintextMetaContent(string: "")
        }

        // language
        status.publisher(for: \.language)
            .assign(to: &$language)
        
        // content warning
        isContentSensitiveToggled = status.isContentSensitiveToggled
        status.publisher(for: \.isContentSensitiveToggled)
            .receive(on: DispatchQueue.main)
            .assign(to: \.isContentSensitiveToggled, on: self)
            .store(in: &disposeBag)
        
        // media
        mediaViewModels = MediaView.ViewModel.viewModels(from: status)
        
        // poll
        if let poll = status.poll {
            self.pollViewModel = PollView.ViewModel(
                authContext: authContext,
                poll: .mastodon(object: poll)
            )
        }
        
        // media content warning
        isMediaSensitive = status.isMediaSensitive
        isMediaSensitiveToggled = status.isMediaSensitiveToggled
        status.publisher(for: \.isMediaSensitiveToggled)
            .receive(on: DispatchQueue.main)
            .assign(to: \.isMediaSensitiveToggled, on: self)
            .store(in: &disposeBag)
            
        // toolbar
        toolbarViewModel.platform = .mastodon
        status.publisher(for: \.replyCount)
            .map { Int($0) }
            .assign(to: &toolbarViewModel.$replyCount)
        status.publisher(for: \.repostCount)
            .map { Int($0) }
            .assign(to: &toolbarViewModel.$repostCount)
        status.publisher(for: \.likeCount)
            .map { Int($0) }
            .assign(to: &toolbarViewModel.$likeCount)
        if case let .mastodon(authenticationContext) = authContext?.authenticationContext {
            status.publisher(for: \.likeBy)
                .map { users -> Bool in
                    let ids = users.map { $0.id }
                    return ids.contains(authenticationContext.userID)
                }
                .assign(to: &toolbarViewModel.$isLiked)
            status.publisher(for: \.repostBy)
                .map { users -> Bool in
                    let ids = users.map { $0.id }
                    return ids.contains(authenticationContext.userID)
                }
                .assign(to: &toolbarViewModel.$isReposted)
        } else {
            // do nothing
        }
        
        // metric
        switch kind {
        case .conversationRoot:
            let _metricViewModel = StatusMetricView.ViewModel(platform: .mastodon, timestamp: status.createdAt)
            metricViewModel = _metricViewModel
            status.publisher(for: \.replyCount)
                .map { Int($0) }
                .assign(to: &_metricViewModel.$replyCount)
            status.publisher(for: \.repostCount)
                .map { Int($0) }
                .assign(to: &_metricViewModel.$repostCount)
            status.publisher(for: \.likeCount)
                .map { Int($0) }
                .assign(to: &_metricViewModel.$likeCount)
        default:
            break
        }
    }
}

extension StatusView.ViewModel {
    public static func prototype(
        viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
    ) -> StatusView.ViewModel {
        let viewModel = StatusView.ViewModel(viewLayoutFramePublisher: viewLayoutFramePublisher)
        
        viewModel.addtionalHorizontalMargin = 20
        
        viewModel.avatarURL = URL(string: "https://pbs.twimg.com/profile_images/809741368134234112/htSiXXAU_400x400.jpg")
        viewModel.authorName = PlaintextMetaContent(string: "Twidere")
        viewModel.authorUsernme = "TwidereProject"
        viewModel.content = TwitterMetaContent.convert(
            document: TwitterContent(content: L10n.Scene.Settings.Display.Preview.thankForUsingTwidereX, urlEntities: []),
            urlMaximumLength: 16,
            twitterTextProvider: SwiftTwitterTextProvider()
        )
        
        return viewModel
//
//        if let repost = status.repost {
//            let _repostViewModel = StatusView.ViewModel(
//                status: repost,
//                authContext: authContext,
//                kind: kind,
//                delegate: delegate,
//                parentViewModel: self,
//                viewLayoutFramePublisher: viewLayoutFramePublisher
//            )
//            repostViewModel = _repostViewModel
//
//            // header - repost
//            let _statusHeaderViewModel = StatusHeaderView.ViewModel(
//                image: Asset.Media.repeat.image.withRenderingMode(.alwaysTemplate),
//                label: {
//                    let name = status.author.name
//                    let userRepostText = L10n.Common.Controls.Status.userBoosted(name)
//                    let text = MastodonContent(content: userRepostText, emojis: status.author.emojis.asDictionary)
//                    let label = MastodonMetaContent.convert(text: text)
//                    return label
//                }()
//            )
//            _statusHeaderViewModel.hasHangingAvatar = _repostViewModel.hasHangingAvatar
//            _repostViewModel.statusHeaderViewModel = _statusHeaderViewModel
//        }
//
//        // author
//        status.author.publisher(for: \.avatar)
//            .compactMap { $0.flatMap { URL(string: $0) } }
//            .assign(to: &$avatarURL)
//        status.author.publisher(for: \.displayName)
//            .compactMap { _ in status.author.nameMetaContent }
//            .assign(to: &$authorName)
//        status.author.publisher(for: \.username)
//            .map { _ in status.author.acct }
//            .assign(to: &$authorUsernme)
//        authorUserIdentifier = .mastodon(.init(domain: status.author.domain, id: status.author.id))
//
//        // visibility
//        visibility = status.visibility
//
//        // timestamp
//        switch kind {
//        case .conversationRoot:
//            break
//        default:
//            timestampLabelViewModel = TimestampLabelView.ViewModel(timestamp: status.createdAt)
//        }
//
//        // spoiler content
//        if let spoilerText = status.spoilerText, !spoilerText.isEmpty {
//            do {
//                let content = MastodonContent(content: spoilerText, emojis: status.emojis.asDictionary)
//                let metaContent = try MastodonMetaContent.convert(document: content, useParagraphMark: true)
//                self.spoilerContent = metaContent
//            } catch {
//                assertionFailure(error.localizedDescription)
//                self.spoilerContent = nil
//            }
//        }
//
//        // content
//        do {
//            let content = MastodonContent(content: status.content, emojis: status.emojis.asDictionary)
//            let metaContent = try MastodonMetaContent.convert(document: content, useParagraphMark: true)
//            self.content = metaContent
//        } catch {
//            assertionFailure(error.localizedDescription)
//            self.content = PlaintextMetaContent(string: "")
//        }
//
//        // language
//        status.publisher(for: \.language)
//            .assign(to: &$language)
//
//        // content warning
//        isContentSensitiveToggled = status.isContentSensitiveToggled
//        status.publisher(for: \.isContentSensitiveToggled)
//            .receive(on: DispatchQueue.main)
//            .assign(to: \.isContentSensitiveToggled, on: self)
//            .store(in: &disposeBag)
//
//        // media
//        mediaViewModels = MediaView.ViewModel.viewModels(from: status)
//
//        // poll
//        if let poll = status.poll {
//            self.pollViewModel = PollView.ViewModel(
//                authContext: authContext,
//                poll: .mastodon(object: poll)
//            )
//        }
//
//        // media content warning
//        isMediaSensitive = status.isMediaSensitive
//        isMediaSensitiveToggled = status.isMediaSensitiveToggled
//        status.publisher(for: \.isMediaSensitiveToggled)
//            .receive(on: DispatchQueue.main)
//            .assign(to: \.isMediaSensitiveToggled, on: self)
//            .store(in: &disposeBag)
//
//        // toolbar
//        toolbarViewModel.platform = .mastodon
//        status.publisher(for: \.replyCount)
//            .map { Int($0) }
//            .assign(to: &toolbarViewModel.$replyCount)
//        status.publisher(for: \.repostCount)
//            .map { Int($0) }
//            .assign(to: &toolbarViewModel.$repostCount)
//        status.publisher(for: \.likeCount)
//            .map { Int($0) }
//            .assign(to: &toolbarViewModel.$likeCount)
//        if case let .mastodon(authenticationContext) = authContext?.authenticationContext {
//            status.publisher(for: \.likeBy)
//                .map { users -> Bool in
//                    let ids = users.map { $0.id }
//                    return ids.contains(authenticationContext.userID)
//                }
//                .assign(to: &toolbarViewModel.$isLiked)
//            status.publisher(for: \.repostBy)
//                .map { users -> Bool in
//                    let ids = users.map { $0.id }
//                    return ids.contains(authenticationContext.userID)
//                }
//                .assign(to: &toolbarViewModel.$isReposted)
//        } else {
//            // do nothing
//        }
//
//        // metric
//        switch kind {
//        case .conversationRoot:
//            let _metricViewModel = StatusMetricView.ViewModel(platform: .mastodon, timestamp: status.createdAt)
//            metricViewModel = _metricViewModel
//            status.publisher(for: \.replyCount)
//                .map { Int($0) }
//                .assign(to: &_metricViewModel.$replyCount)
//            status.publisher(for: \.repostCount)
//                .map { Int($0) }
//                .assign(to: &_metricViewModel.$repostCount)
//            status.publisher(for: \.likeCount)
//                .map { Int($0) }
//                .assign(to: &_metricViewModel.$likeCount)
//        default:
//            break
//        }
    }
}
