//
//  StatusThreadViewModel.swift
//  StatusThreadViewModel
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import GameplayKit
import TwitterSDK
import MastodonSDK
import CoreData
import CoreDataStack

final class StatusThreadViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: "StatusThreadViewModel", category: "ViewModel")
    
    // input
    let context: AppContext
    let twitterStatusThreadReplyViewModel: TwitterStatusThreadReplyViewModel
    let twitterStatusThreadLeafViewModel: TwitterStatusThreadLeafViewModel
    let mastodonStatusThreadViewModel: MastodonStatusThreadViewModel
    let viewDidAppear = PassthroughSubject<Void, Never>()

    // output
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, StatusItem>?
    var root: CurrentValueSubject<StatusItem.Thread?, Never>
    @Published var replies: [StatusItem] = []
    @Published var leafs: [StatusItem] = []
    var threadContext = CurrentValueSubject<ThreadContext?, Never>(nil)
    @Published var hasReplyTo = false
    
    // thread
    private(set) lazy var loadThreadStateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            LoadThreadState.Initial(viewModel: self),
            LoadThreadState.Prepare(viewModel: self),
            LoadThreadState.PrepareFail(viewModel: self),
            LoadThreadState.Idle(viewModel: self),
            LoadThreadState.Loading(viewModel: self),
            LoadThreadState.Fail(viewModel: self),
            LoadThreadState.NoMore(viewModel: self),
            
        ])
        stateMachine.enter(LoadThreadState.Initial.self)
        return stateMachine
    }()

    private init(
        context: AppContext,
        optionalRoot: StatusItem.Thread?
    ) {
        self.context = context
        self.twitterStatusThreadReplyViewModel = TwitterStatusThreadReplyViewModel(context: context)
        self.twitterStatusThreadLeafViewModel = TwitterStatusThreadLeafViewModel(context: context)
        self.mastodonStatusThreadViewModel = MastodonStatusThreadViewModel(context: context)
        self.root = CurrentValueSubject(optionalRoot)
        // end init
        
        viewDidAppear
            .subscribe(twitterStatusThreadReplyViewModel.viewDidAppear)
            .store(in: &disposeBag)
        
        // TODO: handle lazy thread loading
        hasReplyTo = {
            guard case let .root(record) = optionalRoot else { return false }
            guard let status = record.object(in: context.managedObjectContext) else { return false }
            switch status {
            case .twitter(let _status):
                let status = _status.repost ?? _status
                return status.replyToStatusID != nil
            case .mastodon(let _status):
                let status = _status.repost ?? _status
                return status.replyToStatusID != nil
            }
        }()
        
        Publishers.CombineLatest(
            twitterStatusThreadReplyViewModel.$items,
            mastodonStatusThreadViewModel.ancestors
        )
        .map { $0 + $1 }
        .assign(to: &$replies)
        
        Publishers.CombineLatest(
            twitterStatusThreadLeafViewModel.items,
            mastodonStatusThreadViewModel.descendants
        )
        .map { $0 + $1 }
        .assign(to: &$leafs)
    }
    
    convenience init(
        context: AppContext,
        root: StatusItem.Thread
    ) {
        self.init(
            context: context,
            optionalRoot: root
        )
    }
    
}

extension StatusThreadViewModel {
    enum ThreadContext {
        case twitter(TwitterConversation)
        case mastodon(MastodonContext)
        
        struct TwitterConversation {
            let statusID: Twitter.Entity.V2.Tweet.ID
            let authorID: Twitter.Entity.User.ID
            let authorUsername: String
            let createdAt: Date
            
            // V2 only
            let conversationID: Twitter.Entity.V2.Tweet.ConversationID?
        }
        
        struct MastodonContext {
            let domain: String
            let contextID: Mastodon.Entity.Status.ID
            let replyToStatusID: Mastodon.Entity.Status.ID?
        }
    }
}
