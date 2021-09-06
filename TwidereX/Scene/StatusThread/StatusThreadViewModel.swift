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

final class StatusThreadViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: "StatusThreadViewModel", category: "ViewModel")
    
    // input
    let context: AppContext
    let twitterStatusThreadLeafViewModel: TwitterStatusThreadLeafViewModel
    let mastodonStatusThreadViewModel: MastodonStatusThreadViewModel
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<StatusSection, StatusItem>?
    var root: CurrentValueSubject<StatusItem.Thread?, Never>
    var threadContext = CurrentValueSubject<ThreadContext?, Never>(nil)
    
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
        self.twitterStatusThreadLeafViewModel = TwitterStatusThreadLeafViewModel(context: context)
        self.mastodonStatusThreadViewModel = MastodonStatusThreadViewModel(context: context)
        self.root = CurrentValueSubject(optionalRoot)
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
        }
    }
}
