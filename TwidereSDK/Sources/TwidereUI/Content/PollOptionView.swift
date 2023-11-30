//
//  PollOptionView.swift
//  
//
//  Created by MainasuK on 2021-11-29.
//

import os.log
import Foundation
import SwiftUI
import Combine
import MastodonMeta
import CoreDataStack

public struct PollOptionView: View {
    
    @ObservedObject public var viewModel: ViewModel
    @ObservedObject public var themeService = ThemeService.shared
    
    public let selectAction: (ViewModel) -> Void
    
    var bodyFont: UIFont { TextStyle.pollOptionTitle.font }
    var rowHeight: CGFloat {
        let height = abs(bodyFont.ascender) + abs(bodyFont.descender)
        return max(markViewMinHeight + 2 * markViewPadding, height)
    }
    var markViewMinHeight: CGFloat { 20.0 }
    var markViewPadding: CGFloat { 4.0 }
    
    var markView: some View {
        GeometryReader { proxy in
            let tintColor = viewModel.canSelect ? themeService.theme.highlight : themeService.theme.background
            let dimension = proxy.size.width
            CheckmarkView(
                tintColor: tintColor,
                borderWidth: ceil(dimension / 15),
                cornerRadius: viewModel.isMulitpleChoice ? dimension / 6 : dimension / 2,
                check: viewModel.isOptionVoted || viewModel.isSelected
            )
        }
    }
    
    public var body: some View {
        Button {
            selectAction(viewModel)
        } label: {
            let rowHeight = self.rowHeight
            let rowCornerRadius: CGFloat = {
                if viewModel.isMulitpleChoice {
                    return rowHeight / 6
                } else {
                    return rowHeight / 2
                }
            }()
            HStack(spacing: .zero) {
                markView
                    .padding(markViewPadding)
                    .frame(width: rowHeight, height: rowHeight)
                    .opacity(viewModel.canSelect || viewModel.isOptionVoted ? 1 : 0)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center) {
                        LabelRepresentable(
                            metaContent: viewModel.content,
                            textStyle: .pollOptionTitle,
                            setupLabel: { label in
                                label.setupAttributes(foregroundColor: themeService.theme.foreground.withAlphaComponent(0.6))
                                label.setContentHuggingPriority(.required, for: .horizontal)
                                label.setContentCompressionResistancePriority(.required, for: .horizontal)
                            }
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                }   // end ScrollView
                // TODO: https://developer.apple.com/documentation/swiftui/view/scrollbouncebehavior(_:axes:)?changes=latest_minor
                Text(viewModel.percentageText)
                    .font(Font(bodyFont))
                    .foregroundColor(Color(uiColor: themeService.theme.foreground.withAlphaComponent(0.6)))
                    .monospacedDigit()
                    .padding(.horizontal, 6)
                    .opacity(viewModel.isResultReveal ? 1 : 0)
            }
            .frame(height: rowHeight)
            .background(
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Color(uiColor: themeService.theme.highlight.withAlphaComponent(0.15))
                        // note:
                        // Use offset method to keep the perfect circle shape on edges.
                        // So the edge of the bar with percenage likes 0.1 will display as circle
                        // but not rounded square
                        let alpha = viewModel.isOptionVoted ? 0.75 : 0.25
                        let color = themeService.theme.highlight.withAlphaComponent(alpha)
                        let offsetX = proxy.size.width * (1 - viewModel.percentage)
                        Color(uiColor: color)
                            .cornerRadius(rowCornerRadius)
                            .offset(x: -offsetX)    // tweak position
                            .animation(.easeInOut, value: viewModel.percentage)
                            .opacity(viewModel.isResultReveal ? 1 : 0)
                    }
                    .compositingGroup()
                    .cornerRadius(rowCornerRadius)  // clip
                }
            )
        }
        .buttonStyle(.borderless)
    }
}

extension PollOptionView {
    public class ViewModel: ObservableObject, Identifiable {
        
        public var id: Int { index }
        
        // input
        private let authContext: AuthContext?
        @MainActor private let pollOption: PollOptionObject
        
        public let index: Int
        public let content: MetaContent
        public let isMulitpleChoice: Bool
        public let isMyself: Bool
        
        @Published public var isClosed = false
        @Published public var totalVotes: Int = 0
        @Published public var votes: Int = 0
        @Published public var isOptionVoted = false
        @Published public var isPollVoted = false
        @Published public var isSelected: Bool = false
        
        public var canSelect: Bool {
            if isMyself { return false }
            if isClosed { return false }
            if case .twitter = pollOption { return false }
            if isPollVoted || isOptionVoted { return false }
            return true
        }
        public var isResultReveal: Bool {
            return !canSelect
        }
        
        // output
        private static let percentageFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            formatter.numberStyle = .percent
            return formatter
        }()
        public var percentage: Double {
            guard totalVotes > 0 else { return 0.0 }
            return Double(votes) / Double(totalVotes)
        }
        public var percentageText: String {
            let _text = Self.percentageFormatter.string(from: NSNumber(value: percentage)) ?? nil
            return _text ?? ""
        }
        
        public init(
            authContext: AuthContext?,
            pollOption: PollOptionObject,
            isMyself: Bool
        ) {
            self.authContext = authContext
            self.pollOption = pollOption
            self.isMyself = isMyself
            
            assert(Thread.isMainThread)
            switch pollOption {
            case .twitter(let option):
                index = Int(option.position)
                content = PlaintextMetaContent(string: option.label)
                isClosed = true     // cannot vote for Twitter
                isMulitpleChoice = false
                isSelected = false
                votes = Int(option.votes)
                option.publisher(for: \.votes)
                    .map { Int($0) }
                    .assign(to: &$votes)
            case .mastodon(let option):
                index = Int(option.index)
                content = {
                    do {
                        let content = MastodonContent(content: option.title, emojis: option.poll.status.emojisTransient.asDictionary)
                        let metaContent = try MastodonMetaContent.convert(document: content)
                        return metaContent
                    } catch {
                        return PlaintextMetaContent(string: option.title)
                    }
                }()
                isMulitpleChoice = option.poll.multiple
                option.poll.publisher(for: \.expired)
                    .assign(to: &$isClosed)
                votes = Int(option.votesCount)
                option.publisher(for: \.votesCount)
                    .map { Int($0) }
                    .assign(to: &$votes)
                option.publisher(for: \.isSelected)
                    .assign(to: &$isSelected)
            }
            
            switch (authContext?.authenticationContext, pollOption) {
            case (.twitter, .twitter):
                break
            case (.mastodon(let authenticationContext), .mastodon(let option)):
                // bind isVoted
                option.publisher(for: \.voteBy)
                    .map { voteBy in
                        voteBy.contains(where: { $0.id == authenticationContext.userID && $0.domain == authenticationContext.domain })
                    }
                    .assign(to: &$isOptionVoted)
                option.poll.publisher(for: \.voteBy)
                    .map { voteBy in
                        voteBy.contains(where: { $0.id == authenticationContext.userID && $0.domain == authenticationContext.domain })
                    }
                    .assign(to: &$isPollVoted)
            default:
                break
            }
        }   // end init
    }   // end class
}
