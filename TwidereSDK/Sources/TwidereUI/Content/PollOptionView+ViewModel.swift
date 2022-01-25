//
//  PollOptionView+ViewModel.swift
//  
//
//  Created by MainasuK on 2021-12-8.
//

import UIKit
import Combine
import CoreDataStack
import TwidereAsset
import TwitterMeta
import MastodonMeta
import TwidereCore

extension PollOptionView {
    
    static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        formatter.roundingMode = .down
        return formatter
    }()
    
    public final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        var observations = Set<NSKeyValueObservation>()
        
        @Published var style: PollOptionView.Style?
        
        @Published public var content: String = ""          // for edit style
        
        @Published public var metaContent: MetaContent?     // for plain style
        @Published public var percentage: Double?
        
        @Published public var isExpire: Bool = false
        @Published public var isMultiple: Bool = false
        @Published public var isSelect: Bool? = false       // nil for server not return selection array
        @Published public var isPollVoted: Bool = false
        @Published public var isMyPoll: Bool = false
        
        // output
        @Published public var corner: Corner = .none
        @Published public var stripProgressTinitColor: UIColor = .clear
        @Published public var selectImageTintColor: UIColor = Asset.Colors.hightLight.color
        @Published public var isReveal: Bool = false
        
        init() {
            // corner
            $isMultiple
                .map { $0 ? .radius(8) : .circle }
                .assign(to: &$corner)
            // stripProgressTinitColor
            Publishers.CombineLatest3(
                $style,
                $isSelect,
                $isReveal
            )
            .map { style, isSelect, isReveal -> UIColor in
                guard case .plain = style else { return .clear }
                guard isReveal else {
                    return .clear
                }
                
                if isSelect == true {
                    return Asset.Colors.hightLight.color.withAlphaComponent(0.75)
                } else {
                    return Asset.Colors.hightLight.color.withAlphaComponent(0.20)
                }
            }
            .assign(to: &$stripProgressTinitColor)
            // selectImageTintColor
            Publishers.CombineLatest(
                $isSelect,
                $isReveal
            )
            .map { isSelect, isReveal in
                guard let isSelect = isSelect else {
                    return .clear       // none selection state
                }
                
                if isReveal {
                    return isSelect ? .white : .clear
                } else {
                    return Asset.Colors.hightLight.color
                }
            }
            .assign(to: &$selectImageTintColor)
            // isReveal
            Publishers.CombineLatest3(
                $isExpire,
                $isPollVoted,
                $isMyPoll
            )
            .map { isExpire, isPollVoted, isMyPoll in
                return isExpire || isPollVoted || isMyPoll
            }
            .assign(to: &$isReveal)
        }
        
        public enum Corner: Hashable {
            case none
            case circle
            case radius(CGFloat)
        }
    }
}

extension PollOptionView.ViewModel {
    public func bind(view: PollOptionView) {
        // content
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: view.textField)
            .receive(on: DispatchQueue.main)
            .map { _ in view.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }
            .assign(to: &$content)
        // metaContent
        $metaContent
            .sink { metaContent in
                guard let metaContent = metaContent else {
                    view.titleMetaLabel.reset()
                    return
                }
                view.titleMetaLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)
        // percentage
        Publishers.CombineLatest(
            $isReveal,
            $percentage
        )
        .sink { isReveal, percentage in
            guard isReveal else {
                view.percentageMetaLabel.configure(content: PlaintextMetaContent(string: ""))
                return
            }
            
            let oldPercentage = self.percentage
            
            let animated = oldPercentage != nil && percentage != nil
            view.stripProgressView.setProgress(percentage ?? 0, animated: animated)
            
            guard let percentage = percentage,
                  let string = PollOptionView.percentageFormatter.string(from: NSNumber(value: percentage))
            else {
                view.percentageMetaLabel.configure(content: PlaintextMetaContent(string: ""))
                return
            }
            
            view.percentageMetaLabel.configure(content: PlaintextMetaContent(string: string))
        }
        .store(in: &disposeBag)
        // corner
        $corner
            .removeDuplicates()
            .sink { _ in
                view.setNeedsLayout()
            }
            .store(in: &disposeBag)
        // backgroundColor
        $stripProgressTinitColor
            .map { $0 as UIColor? }
            .assign(to: \.tintColor, on: view.stripProgressView)
            .store(in: &disposeBag)
        // selectionImageView
        Publishers.CombineLatest4(
            $style,
            $isMultiple,
            $isSelect,
            $isReveal
        )
        .map { style, isMultiple, isSelect, isReveal -> UIImage? in
            guard case .plain = style else { return nil }
            
            func circle(isSelect: Bool) -> UIImage {
                let image = isSelect ? Asset.Indices.checkmarkCircleFill.image : Asset.Indices.circle.image
                return image.withRenderingMode(.alwaysTemplate)
            }
            
            func square(isSelect: Bool) -> UIImage {
                let image = isSelect ? Asset.Indices.checkmarkSquareFill.image : Asset.Indices.square.image
                return image.withRenderingMode(.alwaysTemplate)
            }
            
            func image(isMultiple: Bool, isSelect: Bool) -> UIImage {
                return isMultiple ? square(isSelect: isSelect) : circle(isSelect: isSelect)
            }
            
            if isReveal {
                guard isSelect == true else {
                    // not display image when isReveal:
                    // - the server not return selection state
                    // - the user not select
                    return nil
                }
                return image(isMultiple: isMultiple, isSelect: true)
            } else {
                return image(isMultiple: isMultiple, isSelect: isSelect == true)
            }
        }
        .sink { image in
            view.selectionImageView.image = image
        }
        .store(in: &disposeBag)
        // selectImageTintColor
        $selectImageTintColor
            .assign(to: \.tintColor, on: view.selectionImageView)
            .store(in: &disposeBag)
    }
}

extension PollOptionView {
    public struct ConfigurationContext {
        public let dateTimeProvider: DateTimeProvider
        public let activeAuthenticationContext: AnyPublisher<AuthenticationContext?, Never>
        
        public init(
            dateTimeProvider: DateTimeProvider,
            activeAuthenticationContext: AnyPublisher<AuthenticationContext?, Never>
        ) {
            self.dateTimeProvider = dateTimeProvider
            self.activeAuthenticationContext = activeAuthenticationContext
        }
    }
}

extension PollOptionView {
    public func configure(
        pollOption option: MastodonPollOption,
        configurationContext: ConfigurationContext
    ) {
        // metaContent
        Publishers.CombineLatest(
            option.poll.status.publisher(for: \.emojis),
            option.publisher(for: \.title)
        )
        .map { emojis, title -> MetaContent? in
            do {
                let content = MastodonContent(content: title, emojis: emojis.asDictionary)
                let metaContent = try MastodonMetaContent.convert(document: content)
                return metaContent
            } catch {
                assertionFailure()
                return PlaintextMetaContent(string: title)
            }
        }
        .assign(to: \.metaContent, on: viewModel)
        .store(in: &disposeBag)

        // $isExpire
        option.poll.publisher(for: \.expired)
            .assign(to: \.isExpire, on: viewModel)
            .store(in: &disposeBag)
        // isMultiple
        viewModel.isMultiple = option.poll.multiple
        
        let optionIndex = option.index
        let authorDomain = option.poll.status.author.domain
        let authorUserID = option.poll.status.author.id
        // isSelect, isPollVoted, isMyPoll
        Publishers.CombineLatest4(
            option.publisher(for: \.poll),
            option.publisher(for: \.voteBy),
            option.publisher(for: \.isSelected),
            configurationContext.activeAuthenticationContext
        )
        .sink { [weak self] poll, optionVoteBy, isSelected, activeAuthenticationContext in
            guard let self = self else { return }
            
            let domain: String
            let userID: String
            switch activeAuthenticationContext {
            case .twitter, .none:
                domain = ""
                userID = ""
            case .mastodon(let authenticationContext):
                domain = authenticationContext.domain
                userID = authenticationContext.userID
            }

            let options = poll.options
            let pollVoteBy = poll.voteBy

            let isMyPoll = authorDomain == domain
                        && authorUserID == userID

            let votedOptions = options.filter { option in
                option.voteBy.contains(where: { $0.id == userID && $0.domain == domain })
            }
            let isRemoteVotedOption = votedOptions.contains(where: { $0.index == optionIndex })
            let isRemoteVotedPoll = pollVoteBy.contains(where: { $0.id == userID && $0.domain == domain })

            let isLocalVotedOption = isSelected

            let isSelect: Bool? = {
                if isLocalVotedOption {
                    return true
                } else if !votedOptions.isEmpty {
                    return isRemoteVotedOption ? true : false
                } else if isRemoteVotedPoll, votedOptions.isEmpty {
                    // the poll voted. But server not mark voted options
                    return nil
                } else {
                    return false
                }
            }()
            self.viewModel.isSelect = isSelect
            self.viewModel.isPollVoted = isRemoteVotedPoll
            self.viewModel.isMyPoll = isMyPoll
        }
        .store(in: &disposeBag)
        // percentage
        Publishers.CombineLatest(
            option.poll.publisher(for: \.votesCount),
            option.publisher(for: \.votesCount)
        )
        .map { pollVotesCount, optionVotesCount -> Double? in
            guard pollVotesCount > 0, optionVotesCount >= 0 else { return 0 }
            return Double(optionVotesCount) / Double(pollVotesCount)
        }
        .assign(to: \.percentage, on: viewModel)
        .store(in: &disposeBag)
    }
}
