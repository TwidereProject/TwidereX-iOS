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

public final class ComposeContentViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    public let composeReplyTableViewCell = ComposeReplyTableViewCell()
    public let composeInputTableViewCell = ComposeInputTableViewCell()
    public let composeAttachmentTableViewCell = ComposeAttachmentTableViewCell()
    
    // input
    public private(set) var replyTo: StatusObject?
    public let contentContext: ContentContext
    @Published public var author: UserObject?
    @Published public internal(set) var attachmentViewModels: [AttachmentViewModel] = []
    @Published public var maxMediaAttachmentLimit = 4
    
    // output
    public var diffableDataSource: UITableViewDiffableDataSource<Section, Item>?
    @Published public internal(set) var items: Set<Item> = [.input]
    @Published public private(set) var availableActions: Set<ComposeToolbarView.Action> = Set()
    @Published public private(set) var isMediaToolBarButtonEnabled = true
    @Published public private(set) var shouldDismiss: Bool = true
    
    public init(
        inputContext: InputContext,
        contentContext: ContentContext
    ) {
        self.contentContext = contentContext
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
                // update itmes
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
        
        // bind toolbar UI 
        Publishers.CombineLatest(
            $attachmentViewModels,
            $maxMediaAttachmentLimit
        )
        .map { attachmentViewModels, maxMediaAttachmentLimit in
            return attachmentViewModels.count < maxMediaAttachmentLimit
        }
        .assign(to: &$isMediaToolBarButtonEnabled)

    }
    
}

extension ComposeContentViewModel {
    public enum InputContext {
        case post
        case hashtag(hashtag: String)
        case mention(user: UserObject)
        case reply(status: StatusObject)
    }
    
    public struct ContentContext {
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
