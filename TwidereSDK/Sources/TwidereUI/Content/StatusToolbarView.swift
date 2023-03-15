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
    let handler: (Action) -> Void
    
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
        }   // end HStack
    }   // end body
    
}

extension StatusToolbarView {
    public var replyButton: some View {
        ToolbarButton(
            handler: { action in
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): reply")
                handler(action)
            },
            action: .reply,
            image: Asset.Arrows.arrowTurnUpLeftMini.image.withRenderingMode(.alwaysTemplate),
            count: viewModel.replyCount,
            tintColor: nil
        )
    }
    
    public var repostButton: some View {
        ToolbarButton(
            handler: { action in
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): repost")
                handler(action)
            },
            action: .repost,
            image: Asset.Media.repeatMini.image.withRenderingMode(.alwaysTemplate),
            count: viewModel.repostCount,
            tintColor: viewModel.isReposted ? Asset.Scene.Status.Toolbar.repost.color : nil
        )
    }
    
    public var repostMenu: some View {
        Menu {
            // repost
            Button {
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): repost")
                handler(.repost)
            } label: {
                Label {
                    Text(L10n.Common.Controls.Status.Actions.retweet)
                } icon: {
                    Image(uiImage: Asset.Media.repeat.image.withRenderingMode(.alwaysTemplate))
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
            image: viewModel.isLiked ? Asset.Health.heartFillMini.image.withRenderingMode(.alwaysTemplate) : Asset.Health.heartMini.image.withRenderingMode(.alwaysTemplate),
            count: viewModel.likeCount,
            tintColor: viewModel.isLiked ? Asset.Scene.Status.Toolbar.like.color : nil
        )
    }
    
    public var shareMenu: some View {
        Button {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): share")
        } label: {
            HStack {
                let image: UIImage = {
                    //                        switch viewModel.kind {
                    //                        case .conversationRoot:
                    return Asset.Editing.ellipsisMini.image.withRenderingMode(.alwaysTemplate)
                    //                        default:
                    //                            return Asset.Editing.ellipsisMini.image.withRenderingMode(.alwaysTemplate)
                    //                        }
                }()
                Image(uiImage: image)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.borderless)
        .modifier(MaxWidthModifier(max: nil))
    }
}

extension StatusToolbarView {
    public class ViewModel: ObservableObject {
        // input
        @Published var platform: Platform = .none
        @Published var replyCount: Int?
        @Published var repostCount: Int?
        @Published var likeCount: Int?
        
        @Published var isReposted: Bool = false
        @Published var isLiked: Bool = false
        
        public init() {
            // end init
        }
    }
}

extension StatusToolbarView {
    public enum Action: Hashable, CaseIterable {
        case reply
        case repost
        case quote
        case like
        case share
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
        var text: String {
            Self.metric(count: count)
        }

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
