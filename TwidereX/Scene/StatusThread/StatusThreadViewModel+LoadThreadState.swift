//
//  StatusThreadViewModel+LoadThreadState.swift
//  StatusThreadViewModel+LoadThreadState
//
//  Created by Cirno MainasuK on 2021-8-31.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit
import CoreDataStack
import TwitterSDK

extension StatusThreadViewModel {
    class LoadThreadState: GKState, NamingState {
        weak var viewModel: StatusThreadViewModel?
        var name: String { "Base" }
        
        init(viewModel: StatusThreadViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, name, (previousState as? NamingState)?.name ?? previousState?.description ?? "nil")
            // guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
        }
    }
}

extension StatusThreadViewModel.LoadThreadState {
    class Initial: StatusThreadViewModel.LoadThreadState {
        override var name: String { "Initial" }
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Prepare.self
        }
    }
    
    class Prepare: StatusThreadViewModel.LoadThreadState {
        override var name: String { "Prepare" }
        let logger = Logger(subsystem: "StatusThreadViewModel.LoadThreadState", category: "Prepare")
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Idle.self || stateClass == PrepareFail.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard case let .root(status) = viewModel.root.value else {
                assertionFailure()
                stateMachine.enter(PrepareFail.self)
                return
            }
            
            Task {
                switch status {
                case .twitter(let record):
                    await prepareTwitterStatusThread(record: record)
                case .mastodon(let record):
                    await prepareMastodonStatusThread(record: record)
                }
            }
        }
        
        // prepare ThreadContext
        // note:
        // The conversationID is V2 only API.
        // Needs query conversationID via V2 endpoint if the status persisted from V1 API.
        func prepareTwitterStatusThread(record: ManagedObjectRecord<TwitterStatus>) async {
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }

            let managedObjectContext = viewModel.context.managedObjectContext
            let _twitterConversation: StatusThreadViewModel.ThreadContext.TwitterConversation? = await managedObjectContext.perform {
                guard let _status = record.object(in: managedObjectContext) else { return nil }
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): resolve status \(_status.id) in local DB")
                
                // Note:
                // make sure unwrap the repost wrapper
                let status = _status.repost ?? _status
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): resolve conversationID \(status.conversationID ?? "<nil>")")
                return StatusThreadViewModel.ThreadContext.TwitterConversation(
                    statusID: status.id,
                    authorID: status.author.id,
                    authorUsername: status.author.username,
                    createdAt: status.createdAt,
                    conversationID: status.conversationID
                )
            }
            guard let twitterConversation = _twitterConversation else {
                stateMachine.enter(PrepareFail.self)
                return
            }
            
            if twitterConversation.conversationID == nil {
                // fetch conversationID if not exist
                guard let authenticationContext = viewModel.context.authenticationService.activeAuthenticationContext.value?.twitterAuthenticationContext else {
                    stateMachine.enter(PrepareFail.self)
                    return
                }
                do {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetching conversationID of \(twitterConversation.statusID)...")
                    let response = try await viewModel.context.apiService.twitterStatus(
                        statusIDs: [twitterConversation.statusID],
                        authenticationContext: authenticationContext
                    )
                    guard let conversationID = response.value.data?.first?.conversationID else {
                        assertionFailure()
                        stateMachine.enter(PrepareFail.self)
                        return
                    }
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch conversationID: \(conversationID)")
                    let newTwitterConversation = StatusThreadViewModel.ThreadContext.TwitterConversation(
                        statusID: twitterConversation.statusID,
                        authorID: twitterConversation.authorID,
                        authorUsername: twitterConversation.authorUsername,
                        createdAt: twitterConversation.createdAt,
                        conversationID: conversationID
                    )
                    viewModel.threadContext.value = .twitter(newTwitterConversation)
                    stateMachine.enter(Idle.self)
                    stateMachine.enter(Loading.self)
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch conversationID failure: \(error.localizedDescription)")
                    stateMachine.enter(PrepareFail.self)
                }
            } else {
                // use cached conversationID
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch cached conversationID: \(twitterConversation.conversationID ?? "<nil>")")
                viewModel.threadContext.value = .twitter(twitterConversation)
                stateMachine.enter(Idle.self)
                stateMachine.enter(Loading.self)
            }
        }
        
        func prepareMastodonStatusThread(record: ManagedObjectRecord<MastodonStatus>) async {
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            let managedObjectContext = viewModel.context.managedObjectContext
            let _mastodonContext: StatusThreadViewModel.ThreadContext.MastodonContext? = await managedObjectContext.perform {
                guard let _status = record.object(in: managedObjectContext) else { return nil }
                
                // Note:
                // make sure unwrap the repost wrapper
                let status = _status.repost ?? _status
                return StatusThreadViewModel.ThreadContext.MastodonContext(
                    domain: status.domain,
                    contextID: status.id
                )
            }
            
            guard let mastodonContext = _mastodonContext else {
                stateMachine.enter(PrepareFail.self)
                return
            }
            
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch cached contextID: \(mastodonContext.contextID)")
            viewModel.threadContext.value = .mastodon(mastodonContext)
            stateMachine.enter(Idle.self)
            stateMachine.enter(Loading.self)
        }
        
    }   // end class Prepare { … }
    
    class PrepareFail: StatusThreadViewModel.LoadThreadState {
        override var name: String { "PrepareFail" }
        var prepareFailCount = 0
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Prepare.self || stateClass == Fail.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            // retry 3 times
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self = self else { return }
                guard let stateMachine = self.stateMachine else { return }
                
                guard self.prepareFailCount < 3 else {
                    stateMachine.enter(Fail.self)
                    return
                }
                self.prepareFailCount += 1
                stateMachine.enter(Prepare.self)
            }
        }
    }
    
    class Idle: StatusThreadViewModel.LoadThreadState {
        override var name: String { "Idle" }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: StatusThreadViewModel.LoadThreadState {
        override var name: String { "Loading" }

//        var needsFallback = false
//
//        var maxID: String?          // v1
        var nextToken: String?      // v2

        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Idle.Type, is NoMore.Type:
                return true
            case is Fail.Type:
                return true
            default:
                return false
            }
        }

        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)

            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let threadContext = viewModel.threadContext.value else {
                assertionFailure()
                return
            }
            
            Task {
                switch threadContext {
                case .twitter(let twitterConversation):
                    let nodes = await fetch(twitterConversation: twitterConversation)
                    await append(nodes: nodes)
                case .mastodon(let mastodonContext):
                    let response = await fetch(mastodonContext: mastodonContext)
                    await append(response: response)
                }
            }
            
//            guard let activeTwitterAuthenticationBox = viewModel.context.authenticationService.activeTwitterAuthenticationBox.value else
//            {
//                assertionFailure()
//                stateMachine.enter(Fail.self)
//                return
//            }
//            guard let conversationMeta = viewModel.conversationMeta.value else {
//                assertionFailure()
//                stateMachine.enter(Fail.self)
//                return
//            }
//
//            if !needsFallback {
//                loadingConversation(viewModel: viewModel, twitterAuthenticationBox: activeTwitterAuthenticationBox, conversationMeta: conversationMeta, stateMachine: stateMachine)
//            } else {
//                loadingConversationFallback(viewModel: viewModel, twitterAuthenticationBox: activeTwitterAuthenticationBox, conversationMeta: conversationMeta, stateMachine: stateMachine)
//            }
        }

        // fetch thread via V2 API
        func fetch(
            twitterConversation: StatusThreadViewModel.ThreadContext.TwitterConversation
        ) async -> [TwitterStatusThreadLeafViewModel.Node] {
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return [] }
            guard let authenticationContext = viewModel.context.authenticationService.activeAuthenticationContext.value?.twitterAuthenticationContext,
                  let conversationID = twitterConversation.conversationID
            else {
                stateMachine.enter(Fail.self)
                return []
            }
            
            let sevenDaysAgo = Date(timeInterval: -((7 * 24 * 60 * 60) - (5 * 60)), since: Date())
            var sinceID: Twitter.Entity.V2.Tweet.ID?
            var startTime: Date?
            
            if twitterConversation.createdAt < sevenDaysAgo {
                startTime = sevenDaysAgo
            } else {
                sinceID = twitterConversation.statusID
            }
            
            do {
                let response = try await viewModel.context.apiService.searchTwitterStatus(
                    conversationID: conversationID,
                    authorID: twitterConversation.authorID,
                    sinceID: sinceID,
                    startTime: startTime,
                    nextToken: nil, // TODO:
                    authenticationContext: authenticationContext
                )
                let nodes = TwitterStatusThreadLeafViewModel.Node.children(
                    of: twitterConversation.statusID,
                    from: response.value
                )
                
                var hasMore = response.value.meta.resultCount != 0
                if let nextToken = response.value.meta.nextToken {
                    self.nextToken = nextToken
                } else {
                    hasMore = false
                }

                if hasMore {
                    stateMachine.enter(Idle.self)
                } else {
                    stateMachine.enter(NoMore.self)
                }
                
                return nodes
            } catch {
                stateMachine.enter(Fail.self)
                return []
            }
        }
        
        @MainActor
        private func append(nodes: [TwitterStatusThreadLeafViewModel.Node]) async {
            guard let viewModel = viewModel else { return }
            viewModel.twitterStatusThreadLeafViewModel.append(nodes: nodes)
        }
        
        @MainActor
        private func append(response: MastodonContextResponse) async {
            guard let viewModel = viewModel else { return }
            
            viewModel.mastodonStatusThreadViewModel.appendAncestor(
                domain: response.domain,
                nodes: response.ancestorNodes
            )
            
            viewModel.mastodonStatusThreadViewModel.appendDescendant(
                domain: response.domain,
                nodes: response.descendantNodes
            )
        }
        
//        func loadingConversation(
//            viewModel: TweetConversationViewModel,
//            twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox,
//            conversationMeta: TweetConversationViewModel.ConversationMeta,
//            stateMachine: GKStateMachine
//        ) {
//            let sevenDaysAgo = Date(timeInterval: -((7 * 24 * 60 * 60) - (5 * 60)), since: Date())
//            var sinceID: Twitter.Entity.V2.Tweet.ID?
//            var startTime: Date?
//            if conversationMeta.createdAt < sevenDaysAgo {
//                startTime = sevenDaysAgo
//            } else {
//                sinceID = conversationMeta.tweetID
//            }
//
//            viewModel.context.apiService.tweetsRecentSearch(
//                conversationID: conversationMeta.conversationID,
//                authorID: conversationMeta.authorID,
//                sinceID: sinceID,
//                startTime: startTime,
//                nextToken: self.nextToken,
//                twitterAuthenticationBox: twitterAuthenticationBox
//            )
//                .receive(on: DispatchQueue.main)
//                .sink { completion in
//                    switch completion {
//                    case .failure(let error):
//                        os_log("%{public}s[%{public}ld], %{public}s: fetch conversation %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, conversationMeta.conversationID, error.localizedDescription)
//                        if let responseError = error as? Twitter.API.Error.ResponseError,
//                           case .rateLimitExceeded = responseError.twitterAPIError {
//                            self.needsFallback = true
//                            stateMachine.enter(Idle.self)
//                            stateMachine.enter(Loading.self)
//                        } else {
//                            stateMachine.enter(Fail.self)
//                        }
//                    case .finished:
//                        break
//                    }
//                } receiveValue: { [weak self] response in
//                    guard let self = self else { return }
//                    let content = response.value
//                    os_log("%{public}s[%{public}ld], %{public}s: fetch conversation %s success. results count %ld", ((#file as NSString).lastPathComponent), #line, #function, conversationMeta.conversationID, content.meta.resultCount)
//
//                    var hasMore = content.meta.resultCount != 0
//                    if let nextToken = content.meta.nextToken {
//                        self.nextToken = nextToken
//                    } else {
//                        hasMore = false
//                    }
//
//                    let childrenForConversationRoot = TweetConversationViewModel.ConversationNode.children(for: conversationMeta.tweetID, from: content)
//                    let nodes = viewModel.conversationNodes.value
//
//                    if hasMore {
//                        stateMachine.enter(Idle.self)
//                    } else {
//                        stateMachine.enter(NoMore.self)
//                    }
//                    viewModel.conversationNodes.value = nodes + childrenForConversationRoot
//                }
//                .store(in: &viewModel.disposeBag)
//        }
//
//        // Fetch conversation via Twitter v1 API
//        func loadingConversationFallback(
//            viewModel: TweetConversationViewModel,
//            twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox,
//            conversationMeta: TweetConversationViewModel.ConversationMeta,
//            stateMachine: GKStateMachine
//        ) {
//            viewModel.context.apiService.tweetsSearch(
//                conversationRootTweetID: conversationMeta.tweetID,
//                authorUsername: conversationMeta.authorUsrename,
//                maxID: maxID,
//                twitterAuthenticationBox: twitterAuthenticationBox
//            )
//                .receive(on: DispatchQueue.main)
//                .sink { completion in
//                    switch completion {
//                    case .failure(let error):
//                        os_log("%{public}s[%{public}ld], %{public}s: fetch conversation %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, conversationMeta.conversationID, error.localizedDescription)
//                        stateMachine.enter(Fail.self)
//                    case .finished:
//                        break
//                    }
//                } receiveValue: { [weak self] response in
//                    guard let self = self else { return }
//                    os_log("%{public}s[%{public}ld], %{public}s: fetch conversation %s success. results count %ld", ((#file as NSString).lastPathComponent), #line, #function, conversationMeta.conversationID, response.value.searchMetadata.count)
//                    let content = response.value
//
//                    let components = URLComponents(string: response.value.searchMetadata.nextResults)
//                    if let maxID = components?.queryItems?.first(where: { $0.name == "max_id" })?.value {
//                        self.maxID = maxID
//                    }
//
//                    let childrenForConversationRoot = TweetConversationViewModel.ConversationNode.children(for: conversationMeta.tweetID, from: content)
//
//                    var hasMore = false
//                    var nodes = viewModel.conversationNodes.value
//                    for child in childrenForConversationRoot {
//                        guard !nodes.contains(where: { $0.tweet.id == child.tweet.id }) else { continue }
//                        nodes.append(child)
//                        hasMore = true
//                    }
//
//                    if hasMore {
//                        stateMachine.enter(Idle.self)
//                    } else {
//                        stateMachine.enter(NoMore.self)
//                    }
//                    viewModel.conversationNodes.value = nodes
//                }
//                .store(in: &viewModel.disposeBag)
//
//        }
        
        struct MastodonContextResponse {
            let domain: String
            let ancestorNodes: [MastodonStatusThreadViewModel.Node]
            let descendantNodes: [MastodonStatusThreadViewModel.Node]
        }
        
        // fetch thread
        func fetch(
            mastodonContext: StatusThreadViewModel.ThreadContext.MastodonContext
        ) async -> MastodonContextResponse {
            guard let viewModel = viewModel, let stateMachine = stateMachine else {
                return MastodonContextResponse(
                    domain: "",
                    ancestorNodes: [],
                    descendantNodes: []
                )
            }
            guard let authenticationContext = viewModel.context.authenticationService.activeAuthenticationContext.value?.mastodonAuthenticationContext
            else {
                stateMachine.enter(Fail.self)
                return MastodonContextResponse(
                    domain: "",
                    ancestorNodes: [],
                    descendantNodes: []
                )
            }
            
            do {
                let response = try await viewModel.context.apiService.mastodonStatusContext(
                    statusID: mastodonContext.contextID,
                    authenticationContext: authenticationContext
                )
                let ancestorNodes = MastodonStatusThreadViewModel.Node.children(
                    of: mastodonContext.contextID,
                    from: response.value.ancestors
                )
                let descendantNodes = MastodonStatusThreadViewModel.Node.children(
                    of: mastodonContext.contextID,
                    from: response.value.descendants
                )

                // update state
                stateMachine.enter(NoMore.self)
                
                return MastodonContextResponse(
                    domain: mastodonContext.domain,
                    ancestorNodes: ancestorNodes,
                    descendantNodes: descendantNodes
                )
            } catch {
                stateMachine.enter(Fail.self)
                return MastodonContextResponse(
                    domain: "",
                    ancestorNodes: [],
                    descendantNodes: []
                )
            }
        }
    }
    
    class Fail: StatusThreadViewModel.LoadThreadState {
        override var name: String { "Fail" }
        
//        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
//            return stateClass == Loading.self
//        }
//
//        override func didEnter(from previousState: GKState?) {
//            super.didEnter(from: previousState)
//            guard let viewModel = viewModel else { return }
//
//            // trigger diffable data source update
//            viewModel.conversationItems.value = viewModel.conversationItems.value
//        }
    }
    
    class NoMore: StatusThreadViewModel.LoadThreadState {
        override var name: String { "NoMore" }
//        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
//            return false
//        }
//
//        override func didEnter(from previousState: GKState?) {
//            super.didEnter(from: previousState)
//            guard let viewModel = viewModel else { return }
//
//            // trigger diffable data source update
//            viewModel.conversationItems.value = viewModel.conversationItems.value
//        }
    }
    
}
