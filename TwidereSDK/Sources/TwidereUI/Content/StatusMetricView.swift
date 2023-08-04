//
//  StatusMetricView.swift
//  
//
//  Created by MainasuK on 2023/3/27.
//

import os.log
import SwiftUI
import CoreDataStack

public struct StatusMetricView: View {
    
    static let logger = Logger(subsystem: "StatusMetricView", category: "View")
    var logger: Logger { StatusView.logger }
    
    @ObservedObject public var viewModel: ViewModel
    public let handler: (Action) -> Void

    public var body: some View {
        VStack {
            HStack {
                Text(viewModel.timestampText)
                    .font(Font(TextStyle.statusMetrics.font))
                    .foregroundColor(Color(uiColor: TextStyle.statusMetrics.textColor))
            }
            HStack(spacing: 16) {
                Spacer()
                replyButton
                repostButton
                switch viewModel.platform {
                case .twitter:
                    quoteButton
                case .mastodon:
                    EmptyView()
                case .none:
                    EmptyView()
                }
                likeButton
                Spacer()
            }
        }
    }
}

extension StatusMetricView {
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
            tintColor: nil
        )
    }
    
    public var quoteButton: some View {
        ToolbarButton(
            handler: { action in
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): quote")
                handler(action)
            },
            action: .quote,
            image: Asset.TextFormatting.textQuoteMini.image.withRenderingMode(.alwaysTemplate),
            count: viewModel.quoteCount,
            tintColor: nil
        )
    }
    
    public var likeButton: some View {
        ToolbarButton(
            handler: { action in
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): like")
                handler(action)
            },
            action: .like,
            image: Asset.Health.heartMini.image.withRenderingMode(.alwaysTemplate),
            count: viewModel.likeCount,
            tintColor: nil
        )
    }
}

extension StatusMetricView {
    public enum Action: Hashable, CaseIterable {
        case reply
        case repost
        case quote
        case like
        
        public var text: String {
            switch self {
            case .reply:        return L10n.Common.Controls.Status.Actions.reply
            case .repost:       return L10n.Common.Controls.Status.Actions.repost
            case .quote:        return L10n.Common.Controls.Status.Actions.quote
            case .like:         return L10n.Common.Controls.Status.Actions.like
            }
        }
        
        public var icon: UIImage {
            switch self {
            case .reply:        return Asset.Arrows.arrowTurnUpLeft.image
            case .repost:       return Asset.Media.repeat.image
            case .quote:        return Asset.TextFormatting.textQuote.image
            case .like:         return Asset.Health.heartFill.image
            }
        }
    }
}

extension StatusMetricView {
    public struct ToolbarButton: View {
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
                        .font(Font(TextStyle.statusMetrics.font))
                        .lineLimit(1)
                }
            }
            .buttonStyle(.borderless)
            .tint(Color(uiColor: tintColor ?? .secondaryLabel))
            .foregroundColor(Color(uiColor: tintColor ?? .secondaryLabel))
        }

        static func metric(count: Int?) -> String {
            guard let count = count, count > 0 else {
                return "0"
            }
            return "\(count)"
        }
    }
}

extension StatusMetricView {
    public class ViewModel: ObservableObject {
        // input
        public let platform: Platform
        public let timestamp: Date
        
        @Published public var source: String?
        @Published public var replyCount: Int = 0
        @Published public var repostCount: Int = 0
        @Published public var quoteCount: Int = 0
        @Published public var likeCount: Int = 0
        
        // output
        public let timestampText: String
        
        public init(
            platform: Platform,
            timestamp: Date
        ) {
            self.platform = platform
            self.timestamp = timestamp
            self.timestampText = {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .medium
                let text = formatter.string(from: timestamp)
                return text
            }()
        }
    }
}
