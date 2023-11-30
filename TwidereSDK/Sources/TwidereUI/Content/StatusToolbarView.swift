//
//  StatusToolbarView.swift
//  
//
//  Created by MainasuK on 2023/3/14.
//

import os.log
import SwiftUI
import CoreDataStack

public struct StatusToolbarView: View {
    
    static let logger = Logger(subsystem: "StatusToolbarView", category: "View")
    var logger: Logger { StatusView.logger }
    
    @ObservedObject public var viewModel: ViewModel
    @ObservedObject public var themeService = ThemeService.shared
    
    public var menuActions: [Action]
    public let handler: (Action) -> Void
    
    public var body: some View {
        HStack {
            replyButton
            Group {
                switch viewModel.platform {
                case .twitter:
                    repostMenu
                case .mastodon:
                    repostButton
                case .none:
                    repostButton
                }
            }
            likeButton
            shareMenu
                .background(
                    WrapperViewRepresentable(view: viewModel.menuButtonBackgroundView)
                )
        }   // end HStack
    }   // end body
    
}

extension StatusToolbarView {
    var isMetricCountDisplay: Bool {
        switch viewModel.style {
        case .inline:       return true
        case .plain:        return false
        }
    }
    
    var isExtraSpacerDisplay: Bool {
        switch viewModel.style {
        case .inline:       return true
        case .plain:        return false
        }
    }
}

extension StatusToolbarView {
    public var replyButton: some View {
        ToolbarButton(
            handler: { action in
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): reply")
                handler(action)
            },
            action: .reply,
            image: viewModel.replyButtonImage,
            count: isMetricCountDisplay ? viewModel.replyCount : nil,
            tintColor: themeService.theme.comment
        )
    }
    
    enum RepostButtonImage {
        case repost
        case repostOff
        case repostLock
        
        static func kind(
            platform: Platform,
            isReposeRestricted: Bool,
            isMyself: Bool
        ) -> Self {
            switch platform {
            case .twitter:
                if isMyself { return .repost }
                if isReposeRestricted { return .repostOff }
                return .repost
            case .mastodon:
                if isReposeRestricted {
                    return isMyself ? .repostLock : .repostOff
                }
                return .repost
            case .none:
                return .repost
            }   // end switch
        }
    }
    
    public var repostButton: some View {
        ToolbarButton(
            handler: { action in
                guard viewModel.isRepostable else { return }
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): repost")
                handler(action)
            },
            action: .repost,
            image: {
                let kind = RepostButtonImage.kind(
                    platform: viewModel.platform,
                    isReposeRestricted: viewModel.isReposeRestricted,
                    isMyself: viewModel.isMyself
                )
                return viewModel.repostButtonImage(kind: kind)
            }(),
            count: isMetricCountDisplay ? viewModel.repostCount : nil,
            tintColor: viewModel.isReposted ? themeService.theme.repost : themeService.theme.comment
        )
        .opacity(viewModel.isRepostable ? 1 : 0.5)
    }
    
    public var repostMenu: some View {
        Menu {
            if viewModel.isRepostable {
                // repost
                Button {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): repost")
                    handler(.repost)
                } label: {
                    Label {
                        let text = viewModel.isReposted ? L10n.Common.Controls.Status.Actions.undoRetweet : L10n.Common.Controls.Status.Actions.retweet
                        Text(text)
                    } icon: {
                        let image = viewModel.isReposted ? Asset.Media.repeatOff.image.withRenderingMode(.alwaysTemplate) : Asset.Media.repeat.image.withRenderingMode(.alwaysTemplate)
                        Image(uiImage: image)
                    }
                }
                // quote
                Button {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): quote")
                    handler(.quote)
                } label: {
                    Label {
                        Text(L10n.Common.Controls.Status.Actions.quote)
                    } icon: {
                        Image(uiImage: Asset.TextFormatting.textQuote.image.withRenderingMode(.alwaysTemplate))
                    }
                }
            }
        } label: {
            repostButton
        }
    }
    
    public var likeButton: some View {
        ToolbarButton(
            handler: { action in
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): like")
                handler(action)
            },
            action: .like,
            image: viewModel.isLiked ? viewModel.likeOnButtonImage : viewModel.likeOffButtonImage,
            count: isMetricCountDisplay ? viewModel.likeCount : nil,
            tintColor: viewModel.isLiked ? themeService.theme.like : themeService.theme.comment
        )
    }
    
    public var shareMenu: some View {
        Menu {
            ForEach(menuActions, id: \.self) { action in
                Button(role: action.isDestructive ? .destructive : nil) {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(String(describing: action))")
                    handler(action)
                } label: {
                    Label {
                        Text(action.text)
                    } icon: {
                        Image(uiImage: action.icon)
                    }
                }   // end Button
            }   // end ForEach
        } label: {
            HStack {
                Image(uiImage: viewModel.moreButtonImage)
                    .foregroundColor(Color(uiColor: themeService.theme.comment))
            }
        }
        .buttonStyle(.borderless)
        .modifier(MaxWidthModifier(max: nil))
    }
}

extension StatusToolbarView {
    public class ViewModel: ObservableObject {
        public let menuButtonBackgroundView = UIView()

        // input
        let style: Style

        @Published var platform: Platform = .none
        
        @Published var replyCount: Int?
        @Published var repostCount: Int?
        @Published var likeCount: Int?
        
        @Published var isReposted: Bool = false
        @Published var isLiked: Bool = false
        
        @Published var isReposeRestricted: Bool = false
        @Published var isMyself: Bool = false
        
        // output
        let replyButtonImage: UIImage
        let repostButtonImage: UIImage
        let repostOffButtonImage: UIImage
        let repostLockButtonImage: UIImage
        let likeOnButtonImage: UIImage
        let likeOffButtonImage: UIImage
        let moreButtonImage: UIImage
        
        var isRepostable: Bool {
            return isMyself || !isReposeRestricted
        }
        
        public init(style: Style) {
            self.style = style
            self.replyButtonImage = {
                switch style {
                case .inline: return Asset.Communication.textBubbleMini.image.withRenderingMode(.alwaysTemplate)
                case .plain: return Asset.Communication.textBubble.image.withRenderingMode(.alwaysTemplate)
                }
            }()
            self.repostButtonImage = {
                switch style {
                case .inline: return Asset.Media.repeatMini.image.withRenderingMode(.alwaysTemplate)
                case .plain: return Asset.Media.repeat.image.withRenderingMode(.alwaysTemplate)
                }
            }()
            self.repostOffButtonImage = {
                switch style {
                case .inline: return Asset.Media.repeatOffMini.image.withRenderingMode(.alwaysTemplate)
                case .plain: return Asset.Media.repeatOff.image.withRenderingMode(.alwaysTemplate)
                }
            }()
            self.repostLockButtonImage = {
                switch style {
                case .inline: return Asset.Media.repeatLockMini.image.withRenderingMode(.alwaysTemplate)
                case .plain: return Asset.Media.repeatLock.image.withRenderingMode(.alwaysTemplate)
                }
            }()
            self.likeOnButtonImage = {
                switch style {
                case .inline: return Asset.Health.heartFillMini.image.withRenderingMode(.alwaysTemplate)
                case .plain: return Asset.Health.heartFill.image.withRenderingMode(.alwaysTemplate)
                }
            }()
            self.likeOffButtonImage = {
                switch style {
                case .inline: return Asset.Health.heartMini.image.withRenderingMode(.alwaysTemplate)
                case .plain: return Asset.Health.heart.image.withRenderingMode(.alwaysTemplate)
                }
            }()
            self.moreButtonImage = {
                switch style {
                case .inline: return Asset.Editing.ellipsisMini.image.withRenderingMode(.alwaysTemplate)
                case .plain: return Asset.Editing.ellipsis.image.withRenderingMode(.alwaysTemplate)
                }
            }()
            // end init
        }
        
        func repostButtonImage(kind: RepostButtonImage) -> UIImage {
            switch kind {
            case .repost: return repostButtonImage
            case .repostOff: return repostOffButtonImage
            case .repostLock: return repostLockButtonImage
            }
        }
    }
}

extension StatusToolbarView {
    public enum Style: Hashable {
        case inline
        case plain
    }

    public enum Action: Hashable, CaseIterable {
        case reply
        case repost
        case quote
        case like
        case copyText
        case copyLink
        case shareLink
        case saveMedia
        case translate
        case delete
        
        public var text: String {
            switch self {
            case .reply:        return L10n.Common.Controls.Status.Actions.reply
            case .repost:       return L10n.Common.Controls.Status.Actions.repost
            case .quote:        return L10n.Common.Controls.Status.Actions.quote
            case .like:         return L10n.Common.Controls.Status.Actions.like
            case .copyText:     return L10n.Common.Controls.Status.Actions.copyText
            case .copyLink:     return L10n.Common.Controls.Status.Actions.copyLink
            case .shareLink:    return L10n.Common.Controls.Status.Actions.shareLink
            case .saveMedia:    return L10n.Common.Controls.Status.Actions.saveMedia
            case .translate:    return L10n.Common.Controls.Status.Actions.translate
            case .delete:       return L10n.Common.Controls.Actions.delete
            }
        }
        
        public var icon: UIImage {
            switch self {
            case .reply:        return Asset.Arrows.arrowTurnUpLeft.image
            case .repost:       return Asset.Media.repeat.image
            case .quote:        return Asset.TextFormatting.textQuote.image
            case .like:         return Asset.Health.heartFill.image
            case .copyText:     return UIImage(systemName: "doc.on.doc")!
            case .copyLink:     return UIImage(systemName: "link")!
            case .shareLink:    return UIImage(systemName: "square.and.arrow.up")!
            case .saveMedia:    return UIImage(systemName: "square.and.arrow.down")!
            case .translate:    return UIImage(systemName: "character.bubble")!
            case .delete:       return UIImage(systemName: "minus.circle")!
            }
        }
        
        public var isDestructive: Bool {
            switch self {
            case .delete:       return true
            default:            return false
            }
        }
    }
}

extension StatusToolbarView {
    public struct ToolbarButton: View {
        static let numberMetricFormatter = NumberMetricFormatter()

        let handler: (Action) -> Void
        let action: Action
        let image: UIImage
        let count: Int?
        let tintColor: UIColor?
        
        // output
        let text: String

        public init(
            handler: @escaping (Action) -> Void,
            action: Action,
            image: UIImage,
            count: Int?,
            tintColor: UIColor?
        ) {
            self.handler = handler
            self.action = action
            self.image = image
            self.count = count
            self.tintColor = tintColor
            self.text = Self.metric(count: count)
        }

        public var body: some View {
            Button {
                handler(action)
            } label: {
                HStack {
                    Image(uiImage: image)
                    Text(text)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    Spacer()
                }
            }
            .buttonStyle(.borderless)
            .tint(Color(uiColor: tintColor ?? .secondaryLabel))
            .foregroundColor(Color(uiColor: tintColor ?? .secondaryLabel))
        }

        static func metric(count: Int?) -> String {
            guard let count = count, count > 0 else {
                return ""
            }
            return ToolbarButton.numberMetricFormatter.string(from: count) ?? ""
        }
    }
}

extension StatusToolbarView {
    public struct MaxWidthModifier: ViewModifier {
        let max: CGFloat?
        
        public init(max: CGFloat?) {
            self.max = max
        }
        
        @ViewBuilder
        public func body(content: Content) -> some View {
            if let max = max {
                content
                    .frame(maxWidth: max)
            } else {
                content
            }
        }
    }
}
