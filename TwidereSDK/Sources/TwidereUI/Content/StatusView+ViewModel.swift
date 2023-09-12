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
        
        let identifier = UUID()
        
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
        @Published public var isAuthorNameContainsMeta: Bool = false
        @Published public var authorUsernme = ""
        public let authorUserIdentifier: UserIdentifier?

        @Published public var protected: Bool = false
        public let isMyself: Bool

        // content
        @Published public var spoilerContent: MetaContent?
        @Published public var spoilerContentAttributedString: AttributedString?
        @Published public var isSpoilerContentContainsMeta: Bool = false
        
        @Published public var content: MetaContent = PlaintextMetaContent(string: "")
        @Published public var contentAttributedString = AttributedString("")
        @Published public var isContentContainsMeta: Bool = false
        
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
        public var isMediaContentWarningOverlayToggleButtonDisplay: Bool {
            switch status {
            case .twitter:      return isMediaSensitive
            default:            return true
            }
        }
        
        // poll
        @Published public var pollViewModel: PollView.ViewModel?

        // visibility
        @Published public var visibility: MastodonVisibility?
        @Published public var visibilityIconImage: UIImage?

//        @Published public var groupedAccessibilityLabel = ""

        // timestamp
        @Published public var timestampLabelViewModel: TimestampLabelView.ViewModel?
        
        // location
        @Published public var location: String?
        
        // metric
        @Published public var metricViewModel: StatusMetricView.ViewModel?

        // toolbar
        public let toolbarViewModel: StatusToolbarView.ViewModel
        public var canDelete: Bool {
            guard let authContext = self.authContext else { return false }
            guard let authorUserIdentifier = self.authorUserIdentifier else { return false }
            return authContext.authenticationContext.userIdentifier == authorUserIdentifier
        }
        
        // reply settings banner
        @Published public var replySettingBannerViewModel: ReplySettingBannerView.ViewModel?

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
            let _authorUserIdentifier: UserIdentifier = {
                switch author {
                case .twitter(let author):
                    return .twitter(.init(id: author.id))
                case .mastodon(let author):
                    return .mastodon(.init(domain: author.domain, id: author.id))
                }
            }()
            self.authorUserIdentifier = _authorUserIdentifier
            self.isMyself = {
                guard let myUserIdentifier = authContext?.authenticationContext.userIdentifier else { return false }
                return myUserIdentifier == _authorUserIdentifier
            }()
            self.toolbarViewModel = StatusToolbarView.ViewModel(style: kind == .conversationRoot ? .plain : .inline)
            // end init
            
            viewLayoutFramePublisher?.assign(to: &$viewLayoutFrame)

            setupBinding()
        }
        
        private init(
             viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
        ) {
            self.status = nil
            self.author = nil
            self.authContext = nil
            self.kind = .timeline
            self.authorUserIdentifier = nil
            self.isMyself = false
            self.toolbarViewModel = StatusToolbarView.ViewModel(style: kind == .conversationRoot ? .plain : .inline)
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
        }
    }
}

extension StatusView.ViewModel {
    @MainActor
    public func updateTwitterStatusContent(statusID: TwitterStatus.ID) async throws {
        do {
            guard case let .twitter(authenticationContext) = authContext?.authenticationContext else { return }
            let response = try await Twitter.API.V2.Status.detail(
                session: URLSession(configuration: .ephemeral),
                query: .init(statusID: statusID),
                authorization: authenticationContext.authorization
            )
            let metaContent = TwitterMetaContent.convert(
                document: TwitterContent(content: response.value.text, urlEntities: response.value.urlEntities),
                urlMaximumLength: .max,
                twitterTextProvider: SwiftTwitterTextProvider(),
                useParagraphMark: true
            )
            self.content = metaContent
            self.contentAttributedString = metaContent.attributedString(accentColor: .tintColor)
            // delegate?.statusView(self, translateContentDidChange: status)
        } catch {
            debugPrint(error.localizedDescription)
            throw error
        }
    }
}

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
        
        // hanging avatar width
        if hasHangingAvatar {
            width += StatusView.hangingAvatarButtonDimension
            width += StatusView.hangingAvatarButtonTrailingSpacing
        }
        
        // manually readable margin (iPad multi-column layout)
        switch kind {
        case .timeline:
            fallthrough
        case .conversationThread:
            fallthrough
        case .conversationRoot:
            if viewLayoutFrame.layoutFrame.width == viewLayoutFrame.readableContentLayoutFrame.width {
                width += 2 * 16
            }
        case .referenceReplyTo:
            break
        case .referenceQuote:
            break
        case .repost:
            break
        case .quote:
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
        case .conversationRoot, .repost, .quote:
            return false
        default:
            return true
        }
    }
    
    var cellTopMargin: CGFloat {
        switch kind {
        case .quote: return .zero
        case _ where parentViewModel == nil: return 12
        default: return .zero
        }
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
        
        // reply settings
        replySettingBannerViewModel = status.replySettingsTransient
            .flatMap { object in Twitter.Entity.V2.Tweet.ReplySettings(rawValue: object.value) }
            .flatMap { replaySettings in
                ReplySettingBannerView.ViewModel(
                    replaySettings: replaySettings,
                    authorUsername: status.author.username
                )
            }

        // author
        status.author.publisher(for: \.profileImageURL)
            .map { _ in status.author.avatarImageURL() }
            .assign(to: &$avatarURL)
        status.author.publisher(for: \.name)
            .map { PlaintextMetaContent(string: $0) }
            .assign(to: &$authorName)
        isAuthorNameContainsMeta = false
        status.author.publisher(for: \.username)
            .assign(to: &$authorUsernme)
        status.author.publisher(for: \.protected)
            .assign(to: &$protected)
        
        // timestamp
        timestampLabelViewModel = TimestampLabelView.ViewModel(timestamp: status.createdAt)
        
        // content
        switch kind {
        case .conversationRoot where status.hasMore:
            let statusID = status.id
            defer {
                Task {
                    try? await self.updateTwitterStatusContent(statusID: statusID)
                }
            }
            fallthrough
        default:
            let content = TwitterContent(content: status.displayText, urlEntities: status.urlEntities)
            let metaContent = TwitterMetaContent.convert(
                document: content,
                urlMaximumLength: .max,
                twitterTextProvider: SwiftTwitterTextProvider(),
                useParagraphMark: true
            )
            self.content = metaContent
            self.contentAttributedString = metaContent.attributedString(accentColor: .tintColor)
            self.isContentContainsMeta = false
        }
        
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
        
        // media content warning
        isMediaSensitive = status.isMediaSensitive
        isMediaSensitiveToggled = status.isMediaSensitiveToggled
        status.publisher(for: \.isMediaSensitiveToggled)
            .receive(on: DispatchQueue.main)
            .assign(to: \.isMediaSensitiveToggled, on: self)
            .store(in: &disposeBag)
        
        // poll
        if let poll = status.poll {
            self.pollViewModel = PollView.ViewModel(
                authContext: authContext,
                poll: .twitter(object: poll)
            )
        }

        // location
        location = status.locationTransient?.fullName

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
        toolbarViewModel.isMyself = isMyself
        status.publisher(for: \.replyCount)
            .map { Int($0) }
            .assign(to: &toolbarViewModel.$replyCount)
        status.publisher(for: \.repostCount)
            .map { Int($0) }
            .assign(to: &toolbarViewModel.$repostCount)
        status.publisher(for: \.likeCount)
            .map { Int($0) }
            .assign(to: &toolbarViewModel.$likeCount)
        status.author.publisher(for: \.protected)
            .assign(to: &toolbarViewModel.$isReposeRestricted)
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
                    let text = MastodonContent(content: userRepostText, emojis: status.author.emojisTransient.asDictionary)
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
        isAuthorNameContainsMeta = !status.author.emojisTransient.isEmpty
        status.author.publisher(for: \.username)
            .map { _ in status.author.acct }
            .assign(to: &$authorUsernme)
        status.author.publisher(for: \.locked)
            .assign(to: &$protected)

        // visibility
        let _visibility = status.visibility
        visibility = _visibility
        visibilityIconImage = {
            switch _visibility {
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
            }
        }()

        // timestamp
        timestampLabelViewModel = TimestampLabelView.ViewModel(timestamp: status.createdAt)
        
        // spoiler content
        if let spoilerText = status.spoilerText, !spoilerText.isEmpty {
            do {
                let content = MastodonContent(content: spoilerText, emojis: status.emojisTransient.asDictionary)
                let metaContent = try MastodonMetaContent.convert(document: content, useParagraphMark: true)
                self.spoilerContent = metaContent
                self.spoilerContentAttributedString = metaContent.attributedString(accentColor: .tintColor)
                self.isSpoilerContentContainsMeta = !status.emojisTransient.isEmpty
            } catch {
                assertionFailure(error.localizedDescription)
                self.spoilerContent = nil
                self.spoilerContentAttributedString = nil
            }
        }
        
        // content
        do {
            let content = MastodonContent(content: status.content, emojis: status.emojisTransient.asDictionary)
            let metaContent = try MastodonMetaContent.convert(document: content, useParagraphMark: true)
            self.content = metaContent
            self.contentAttributedString = metaContent.attributedString(accentColor: .tintColor)
            self.isContentContainsMeta = !status.emojisTransient.isEmpty
        } catch {
            assertionFailure(error.localizedDescription)
            self.content = PlaintextMetaContent(string: "")
            self.contentAttributedString = AttributedString("")
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
        toolbarViewModel.isMyself = isMyself
        status.publisher(for: \.replyCount)
            .map { Int($0) }
            .assign(to: &toolbarViewModel.$replyCount)
        status.publisher(for: \.repostCount)
            .map { Int($0) }
            .assign(to: &toolbarViewModel.$repostCount)
        status.publisher(for: \.likeCount)
            .map { Int($0) }
            .assign(to: &toolbarViewModel.$likeCount)
        toolbarViewModel.isReposeRestricted = {
            switch status.visibility {
            case .public:       return false
            case .unlisted:     return false
            case .direct:       return true
            case .private:      return true
            case ._other:
                assertionFailure()
                return false
            }
        }()
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
        let metaContent = TwitterMetaContent.convert(
            document: TwitterContent(content: L10n.Scene.Settings.Display.Preview.thankForUsingTwidereX, urlEntities: []),
            urlMaximumLength: 16,
            twitterTextProvider: SwiftTwitterTextProvider()
        )
        viewModel.content = metaContent
        viewModel.contentAttributedString = metaContent.attributedString(accentColor: .tintColor)
        
        return viewModel
    }
}
