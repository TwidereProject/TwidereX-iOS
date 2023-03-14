//
//  PollOptionView+Configuration.swift
//  
//
//  Created by MainasuK on 2022-6-10.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import TwidereAsset
import TwitterMeta
import MastodonMeta
import TwidereCore

//extension PollOptionView {
//    public typealias ConfigurationContext = StatusView.ConfigurationContext
//}

extension PollOptionView {
    
    public func configure(
        pollOption: PollOptionObject
//        configurationContext: ConfigurationContext
    ) {
//        switch pollOption {
//        case .twitter(let object):
//            configure(
//                pollOption: object,
//                configurationContext: configurationContext
//            )
//        case .mastodon(let object):
//            configure(
//                pollOption: object,
//                configurationContext: configurationContext
//            )
//        }
    }
    
//    public func configure(
//        pollOption option: TwitterPollOption,
//        configurationContext: ConfigurationContext
//    ) {
//        viewModel.objects.insert(option)
//
//        // metaContent
//        viewModel.metaContent = PlaintextMetaContent(string: option.label)
//
//        // $isExpire
//        viewModel.isExpire = true       // cannot vote for Twitter
//
//        // isMultiple
//        viewModel.isMultiple = false
//
//        // isSelect, isPollVoted, isMyPoll
//        viewModel.isSelect = false
//        viewModel.isPollVoted = false
//        viewModel.isMyPoll = false
//
//        // percentage
//        Publishers.CombineLatest(
//            option.poll.publisher(for: \.updatedAt),
//            option.publisher(for: \.votes)
//        )
//        .map { _, optionVotesCount -> Double? in
//            let pollVotesCount: Int = option.poll.options.map({ Int($0.votes) }).reduce(0, +)
//            guard pollVotesCount > 0, optionVotesCount >= 0 else { return 0 }
//            return Double(optionVotesCount) / Double(pollVotesCount)
//        }
//        .assign(to: \.percentage, on: viewModel)
//        .store(in: &disposeBag)
//    }
    
//    public func configure(
//        pollOption option: MastodonPollOption,
//        configurationContext: ConfigurationContext
//    ) {
//        viewModel.objects.insert(option)
//
//        // metaContent
//        Publishers.CombineLatest(
//            option.poll.status.publisher(for: \.emojis),
//            option.publisher(for: \.title)
//        )
//        .map { emojis, title -> MetaContent? in
//            do {
//                let content = MastodonContent(content: title, emojis: emojis.asDictionary)
//                let metaContent = try MastodonMetaContent.convert(document: content)
//                return metaContent
//            } catch {
//                assertionFailure()
//                return PlaintextMetaContent(string: title)
//            }
//        }
//        .assign(to: \.metaContent, on: viewModel)
//        .store(in: &disposeBag)
//
//        // $isExpire
//        option.poll.publisher(for: \.expired)
//            .assign(to: \.isExpire, on: viewModel)
//            .store(in: &disposeBag)
//        // isMultiple
//        viewModel.isMultiple = option.poll.multiple
//        
//        let optionIndex = option.index
//        let authorDomain = option.poll.status.author.domain
//        let authorUserID = option.poll.status.author.id
//        // isSelect, isPollVoted, isMyPoll
//        Publishers.CombineLatest4(
//            option.publisher(for: \.poll),
//            option.publisher(for: \.voteBy),
//            option.publisher(for: \.isSelected),
//            viewModel.$authenticationContext
//        )
//        .sink { [weak self] poll, optionVoteBy, isSelected, authenticationContext in
//            guard let self = self else { return }
//            
//            let domain: String
//            let userID: String
//            switch authenticationContext {
//            case .twitter, .none:
//                domain = ""
//                userID = ""
//            case .mastodon(let authenticationContext):
//                domain = authenticationContext.domain
//                userID = authenticationContext.userID
//            }
//
//            let options = poll.options
//            let pollVoteBy = poll.voteBy
//
//            let isMyPoll = authorDomain == domain
//                        && authorUserID == userID
//
//            let votedOptions = options.filter { option in
//                option.voteBy.contains(where: { $0.id == userID && $0.domain == domain })
//            }
//            let isRemoteVotedOption = votedOptions.contains(where: { $0.index == optionIndex })
//            let isRemoteVotedPoll = pollVoteBy.contains(where: { $0.id == userID && $0.domain == domain })
//
//            let isLocalVotedOption = isSelected
//
//            let isSelect: Bool? = {
//                if isLocalVotedOption {
//                    return true
//                } else if !votedOptions.isEmpty {
//                    return isRemoteVotedOption ? true : false
//                } else if isRemoteVotedPoll, votedOptions.isEmpty {
//                    // the poll voted. But server not mark voted options
//                    return nil
//                } else {
//                    return false
//                }
//            }()
//            self.viewModel.isSelect = isSelect
//            self.viewModel.isPollVoted = isRemoteVotedPoll
//            self.viewModel.isMyPoll = isMyPoll
//        }
//        .store(in: &disposeBag)
//        // percentage
//        Publishers.CombineLatest(
//            option.poll.publisher(for: \.votesCount),
//            option.publisher(for: \.votesCount)
//        )
//        .map { pollVotesCount, optionVotesCount -> Double? in
//            guard pollVotesCount > 0, optionVotesCount >= 0 else { return 0 }
//            return Double(optionVotesCount) / Double(pollVotesCount)
//        }
//        .assign(to: \.percentage, on: viewModel)
//        .store(in: &disposeBag)
//    }
    
}
