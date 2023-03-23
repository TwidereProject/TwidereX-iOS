//
//  PollView.swift
//  
//
//  Created by MainasuK on 2023/3/21.
//

import os.log
import Foundation
import SwiftUI
import Combine
import MastodonMeta
import CoreDataStack

public struct PollView: View {
    
    static let logger = Logger(subsystem: "PollView", category: "View")
    var logger: Logger { PollView.logger }
    
    @ObservedObject public var viewModel: ViewModel
    public let selectAction: (PollOptionView.ViewModel) -> Void
    public let voteAction: (ViewModel) -> Void
    
    public var body: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.options) { option in
                PollOptionView(viewModel: option) { optionViewModel in
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(optionViewModel.index)")
                    selectAction(optionViewModel)
                }
//                VStack {
//                    HStack {
//                        Text(option.content)
//                            .font(.system(size: 16, weight: .regular))
//                            .foregroundColor(Color(uiColor: Asset.Color.M3.Sys.onSurface.color))
//                        Spacer()
//                    }
//                    HStack(alignment: .center) {
//                        GeometryReader { proxy in
//                            RoundedRectangle(cornerRadius: proxy.size.height / 2)
//                                .frame(width: proxy.size.width)
//                                .foregroundColor(Color(uiColor: Asset.Color.M3.Sys.surfaceVariant.color))
//                                .overlay(
//                                    HStack {
//                                        let gradient = Gradient(stops: [
//                                            .init(color: Color(uiColor: UIColor(hex: 0xFF7575)), location: 0.0),
//                                            .init(color: Color(uiColor: UIColor(hex: 0x8B54FF)), location: 1.0),
//                                        ])
//                                        LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing)
//                                            .foregroundColor(Color(uiColor: Asset.Color.Sys.primary.color))
//                                            .mask(alignment: .leading) {
//                                                RoundedRectangle(cornerRadius: proxy.size.height / 2)
//                                                    .frame(width: proxy.size.width * (option.percentage ?? 0))
//                                            }
//                                    }
//                                    .frame(alignment: .leading)
//                                )
//                                .clipShape(
//                                    RoundedRectangle(cornerRadius: proxy.size.height / 2)
//                                )
//                        }
//                        .frame(height: 12)
//                        Text("99.99%")      // fixed width size
//                            .lineLimit(1)
//                            .font(.system(size: 14, weight: .regular))
//                            .foregroundColor(.clear)
//                            .overlay(
//                                HStack(spacing: .zero) {
//                                    Spacer()
//                                    Text(option.percentageText)
//                                        .lineLimit(1)
//                                        .font(.system(size: 14, weight: .regular))
//                                        .foregroundColor(Color(uiColor: Asset.Color.secondary.color))
//                                        .fixedSize(horizontal: true, vertical: false)
//                                }
//                            )
//                    }
//                }
            }   // end ForEach
            HStack {
                Text(verbatim: viewModel.pollDescription)
                    .font(Font(TextStyle.pollVoteDescription.font))
                    .lineLimit(TextStyle.pollVoteDescription.numberOfLines)
                    .foregroundColor(Color(uiColor: TextStyle.pollVoteDescription.textColor))
                Spacer()
                if viewModel.isVoteButtonDisplay {
                    Button {
                        guard viewModel.isVoteButtonEnabled else { return }
                        guard !viewModel.isVoting else { return }
                        voteAction(viewModel)
                    } label: {
                        let textColor = viewModel.isVoteButtonEnabled ? TextStyle.pollVoteButton.textColor : .secondaryLabel
                        Text(L10n.Common.Controls.Status.Actions.vote)
                            .font(Font(TextStyle.pollVoteButton.font))
                            .lineLimit(TextStyle.pollVoteButton.numberOfLines)
                            .foregroundColor(Color(uiColor: textColor))
                            .opacity(viewModel.isVoting ? 0 : 1)
                            .overlay {
                                if viewModel.isVoting {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.secondary)
                                }
                            }
                    }
                    .buttonStyle(.borderless)
                }
            }
        }   // end VStack
    }
    
    var pollDescriptionLabelTintColor: Color {
        let color = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            // TODO: use new color palate
            case .light:        return UIColor(hex: 0xABABA9)
            default:            return UIColor(hex: 0x5A5E6C)
            }
        }
        return Color(uiColor: color)
    }

}

extension PollView {
    public class ViewModel: ObservableObject {
        
        var disposeBag = Set<AnyCancellable>()
        
        // input
        private let authContext: AuthContext?
        @MainActor private let poll: PollObject
        
        public let platform: Platform
        public let endDate: Date?
        public let isMyself: Bool
        
        @Published public var options: [PollOptionView.ViewModel] = []
        @Published public var isClosed = false
        @Published public var isVoting = false
        @Published public var isPollVoted = false
        
        // output
        @Published public var votesCount = 0
        @Published public var isVoteButtonEnabled = true
        public var isVoteButtonDisplay: Bool {
            return !isMyself && !isClosed && !isPollVoted
        }

        public var pollDescription: String {
            var texts: [String] = []
            switch platform {
            case .none:
                return ""
            case .twitter:
                let peopleCount = votesCount
                texts.append(L10n.Count.people(peopleCount))
            case .mastodon:
                texts.append(L10n.Count.vote(votesCount))
            }
            if isClosed {
                texts.append(L10n.Common.Controls.Status.Poll.expired)
            } else if let endDate = endDate {
                let now = Date()
                let timeInterval = endDate.timeIntervalSince(now)
                if timeInterval > 0, let text = endDate.localizedTimeLeft {
                    texts.append(text)
                }
            }
            return texts.joined(separator: " · ")
        }
        
        @MainActor
        public var needsUpdate: Bool {
            return poll.needsUpdate
        }
        
        public init(
            authContext: AuthContext?,
            poll: PollObject
        ) {
            self.authContext = authContext
            self.poll = poll
            let isMyself = {
                switch authContext?.authenticationContext {
                case .twitter(let authenticationContext):
                    guard case let .twitter(poll) = poll else {
                        assertionFailure()
                        return false
                    }
                    return authenticationContext.userID == poll.status.author.id
                case .mastodon(let authenticationContext):
                    guard case let .mastodon(poll) = poll else {
                        assertionFailure()
                        return false
                    }
                    return  authenticationContext.userID == poll.status.author.id && authenticationContext.domain == poll.status.author.domain
                default:
                    return false
                }
            }()
            self.isMyself = isMyself
            
            switch poll {
            case .twitter(let poll):
                platform = .twitter
                options = poll.options
                    .sorted(by: { $0.position < $1.position })
                    .map {
                        PollOptionView.ViewModel(
                            authContext: authContext,
                            pollOption: .twitter(object: $0),
                            isMyself: isMyself
                        )
                    }
                endDate = poll.endDatetime
                isClosed = true     // cannot vote for Twitter
            case .mastodon(let poll):
                platform = .mastodon
                options = poll.options
                    .sorted(by: { $0.index < $1.index })
                    .map {
                        PollOptionView.ViewModel(
                            authContext: authContext,
                            pollOption: .mastodon(object: $0),
                            isMyself: isMyself
                        )
                    }
                endDate = poll.expiresAt
                poll.publisher(for: \.expired)
                    .assign(to: &$isClosed)
                poll.publisher(for: \.isVoting)
                    .assign(to: &$isVoting)
                if case let .mastodon(authenticationContext) = authContext?.authenticationContext {
                    poll.publisher(for: \.voteBy)
                        .map { voteBy in
                            voteBy.contains(where: { $0.id == authenticationContext.userID && $0.domain == authenticationContext.domain })
                        }
                        .assign(to: &$isPollVoted)
                }
            }
            
            // collect votes into votesCount
            Publishers.MergeMany(options.map { $0.$votes })
                .receive(on: DispatchQueue.main)
                .compactMap { [weak self]  _ in
                    guard let self = self else { return nil }
                    return self.options
                        .map { $0.votes }
                        .reduce(0, +)
                }
                .removeDuplicates()
                .assign(to: \.votesCount, on: self)
                .store(in: &disposeBag)

            // bind votesCount
            $votesCount
                .removeDuplicates()
                .sink { [weak self] totalVotes in
                    guard let self = self else { return }
                    self.options.forEach { option in
                        option.totalVotes = totalVotes
                    }
                }
                .store(in: &disposeBag)
            
            // bind canVote
            Publishers.MergeMany(options.map { $0.$isSelected })
                .receive(on: DispatchQueue.main)
                .compactMap { [weak self] _ in
                    guard let self = self else { return nil }
                    return self.options
                        .map { $0.isSelected }
                        .contains(true)
                }
                .removeDuplicates()
                .assign(to: \.isVoteButtonEnabled, on: self)
                .store(in: &disposeBag)
        }
    }
}

