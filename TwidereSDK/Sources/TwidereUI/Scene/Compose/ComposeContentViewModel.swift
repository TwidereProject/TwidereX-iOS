//
//  ComposeContentViewModel.swift
//  
//
//  Created by MainasuK on 2021/11/17.
//

import UIKit
import SwiftUI
import Combine
import TwidereCore
import TwitterMeta
import MetaTextKit
import MastodonMeta

public final class ComposeContentViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    public let composeReplyTableViewCell = ComposeReplyTableViewCell()
    public let composeInputTableViewCell = ComposeInputTableViewCell()
    public let composeAttachmentTableViewCell = ComposeAttachmentTableViewCell()
    
    // Input
    public let configurationContext: ConfigurationContext
    
    // text
    @Published public private(set) var initialTextInput = ""
    
    // avatar
    @Published public var author: UserObject?
    
    // reply-to
    public private(set) var replyTo: StatusObject?
    
    // attachment
    @Published public internal(set) var attachmentViewModels: [AttachmentViewModel] = []
    @Published public var maxMediaAttachmentLimit = 4
    
    // Output
    public var diffableDataSource: UITableViewDiffableDataSource<Section, Item>?
    @Published public private(set) var items: Set<Item> = [.input]
    
    // text
    @Published public var maxTextInputLimit = 500
    @Published public var textInputLimitProgress: CGFloat = 0.0
    @Published public var isTextInputEmpty = true
    @Published public var isTextInputValid = true
    @Published public var currentTextInput = ""
    
    // emoji
    @Published public private(set) var emojiViewModel: MastodonEmojiService.EmojiViewModel? = nil
    
    // toolbar
    @Published public private(set) var availableActions: Set<ComposeToolbarView.Action> = Set()
    @Published public private(set) var isMediaToolBarButtonEnabled = true
    
    // UI state
    @Published public private(set) var isComposeBarButtonEnabled = true
    @Published public private(set) var canDismissDirectly = true
    @Published public var additionalSafeAreaInsets: UIEdgeInsets = .zero
    let viewDidAppear = CurrentValueSubject<Void, Never>(Void())
    let viewLayoutMarginDidUpdate = CurrentValueSubject<Void, Never>(Void())
    
    public init(
        inputContext: InputContext,
        configurationContext: ConfigurationContext
    ) {
        self.configurationContext = configurationContext
        // end init

        switch inputContext {
        case .post:
            break
        case .hashtag(let hashtag):
            break
        case .mention(let user):
            break
        case .reply(let status):
            replyTo = status
            items.insert(.replyTo)
        }
        // TODO: set availableActions
        
        // bind author
        $author
            .sink { [weak self] author in
                guard let self = self else { return }
                self.composeInputTableViewCell.configure(user: author)
            }
            .store(in: &disposeBag)
        
        // bind attachments
        $attachmentViewModels
            .sink { [weak self] attachmentViewModels in
                guard let self = self else { return }
                // update items
                if attachmentViewModels.isEmpty {
                    self.items.remove(.attachment)
                } else {
                    self.items.insert(.attachment)
                }
                // update data source
                var snapshot = NSDiffableDataSourceSnapshot<ComposeAttachmentTableViewCell.Section, ComposeAttachmentTableViewCell.Item>()
                snapshot.appendSections([.main])
                let items: [ComposeAttachmentTableViewCell.Item] = attachmentViewModels.map {
                    ComposeAttachmentTableViewCell.Item.attachment(viewModel: $0)
                }
                snapshot.appendItems(items, toSection: .main)
                self.composeAttachmentTableViewCell.diffableDataSource.apply(snapshot)
            }
            .store(in: &disposeBag)
        
        // bind toolbar
        $author
            .map { author -> Set<ComposeToolbarView.Action> in
                var set = Set<ComposeToolbarView.Action>()
                set.insert(.media)
                set.insert(.mention)
                set.insert(.hashtag)
                set.insert(.media)
                
                switch author {
                case .twitter:
                    set.insert(.location)
                case .mastodon:
                    set.insert(.emoji)
                    set.insert(.poll)
                    set.insert(.contentWarning)
                    set.insert(.mediaSensitive)
                case .none:
                    break
                }
                return set
            }
            .assign(to: &$availableActions)
        
        Publishers.CombineLatest(
            $attachmentViewModels,
            $maxMediaAttachmentLimit
        )
        .map { attachmentViewModels, maxMediaAttachmentLimit in
            return attachmentViewModels.count < maxMediaAttachmentLimit
        }
        .assign(to: &$isMediaToolBarButtonEnabled)

        
        // bind UI state
        Publishers.CombineLatest(
            $isTextInputEmpty,
            $isTextInputValid
        )
        .map { !$0 && $1 }
        .assign(to: &$isComposeBarButtonEnabled)
        
        Publishers.CombineLatest(
            $initialTextInput,
            $currentTextInput
        )
        .map { initialTextInput, currentTextInput in
            return initialTextInput.trimmingCharacters(in: .whitespacesAndNewlines) == currentTextInput.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .assign(to: &$canDismissDirectly)
    }
    
}

extension ComposeContentViewModel {
    public enum InputContext {
        case post
        case hashtag(hashtag: String)
        case mention(user: UserObject)
        case reply(status: StatusObject)
    }
    
    public struct ConfigurationContext {
        public let dateTimeProvider: DateTimeProvider
        public let twitterTextProvider: TwitterTextProvider
        
        public init(
            dateTimeProvider: DateTimeProvider,
            twitterTextProvider: TwitterTextProvider
        ) {
            self.dateTimeProvider = dateTimeProvider
            self.twitterTextProvider = twitterTextProvider
        }
    }
}

extension ComposeContentViewModel {
    func processEditing(textStorage: MetaTextStorage) -> MetaContent? {
        guard let author = self.author else {
            return nil
        }
        
        let textInput = textStorage.string
        self.currentTextInput = textInput

        switch author {
        case .twitter:
            let content = TwitterContent(content: textInput)
            let metaContent = TwitterMetaContent.convert(
                content: content,
                urlMaximumLength: .max,
                twitterTextProvider: configurationContext.twitterTextProvider
            )
            
            // set text limit
            let parseResult = configurationContext.twitterTextProvider.parse(text: textInput)
            textInputLimitProgress = {
                guard parseResult.maxWeightedLength > 0 else { return .zero }
                return CGFloat(parseResult.weightedLength) / CGFloat(parseResult.maxWeightedLength)
            }()
            maxTextInputLimit = parseResult.maxWeightedLength
            isTextInputValid = parseResult.isValid
            
            return metaContent
            
        case .mastodon:
            let content = MastodonContent(
                content: textInput,
                emojis: emojiViewModel?.emojis.asDictionary ?? [:]
            )
            let metaContent = MastodonMetaContent.convert(text: content)
            return metaContent
        }
    }
}


//extension ComposeContentViewModel {
//    public struct State: OptionSet {
//
//        public let rawValue: Int
//
//        public init(rawValue: Int) {
//            self.rawValue = rawValue
//        }
//
//        // FIXME: use stencil template generate
//        public static let media = ComposeToolbarView.Action.media.option
//        public static let emoji = ComposeToolbarView.Action.emoji.option
//        public static let poll = ComposeToolbarView.Action.poll.option
//        public static let mention = ComposeToolbarView.Action.mention.option
//        public static let hashtag = ComposeToolbarView.Action.hashtag.option
//        public static let location = ComposeToolbarView.Action.location.option
//    }
//}
//
//extension ComposeToolbarView.Action {
//    public var option: ComposeContentViewModel.State {
//        return ComposeContentViewModel.State(rawValue: 1 << rawValue)
//    }
//}
