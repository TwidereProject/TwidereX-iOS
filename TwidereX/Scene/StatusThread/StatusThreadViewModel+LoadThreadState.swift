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
            super.didEnter(from: previousState)
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
            guard case let .root(threadContext) = viewModel.root.value else {
                assertionFailure()
                stateMachine.enter(PrepareFail.self)
                return
            }
            
            Task {
                switch threadContext.status {
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
                guard case let .twitter(authenticationContext) = viewModel.authContext.authenticationContext else {
                    await enter(state: PrepareFail.self)
                    return
                }
                do {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetching conversationID of \(twitterConversation.statusID)...")
                    let response = try await viewModel.context.apiService.twitterStatus(
                        statusIDs: [twitterConversation.statusID],
                        authenticationContext: authenticationContext
                    )
                    guard let conversationID = response.value.data?.first?.conversationID else {
                        // assertionFailure()
                        await enter(state: PrepareFail.self)
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
                    await enter(state: Idle.self)
                    await enter(state: Loading.self)
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch conversationID failure: \(error.localizedDescription)")
                    await enter(state: PrepareFail.self)
                }
            } else {
                // use cached conversationID
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch cached conversationID: \(twitterConversation.conversationID ?? "<nil>")")
                viewModel.threadContext.value = .twitter(twitterConversation)
                await enter(state: Idle.self)
                await enter(state: Loading.self)
            }
        }
        
        func prepareMastodonStatusThread(record: ManagedObjectRecord<MastodonStatus>) async {
            guard let viewModel = viewModel else { return }
            
            let managedObjectContext = viewModel.context.managedObjectContext
            let _mastodonContext: StatusThreadViewModel.ThreadContext.MastodonContext? = await managedObjectContext.perform {
                guard let _status = record.object(in: managedObjectContext) else { return nil }
                
                // Note:
                // make sure unwrap the repost wrapper
                let status = _status.repost ?? _status
                return StatusThreadViewModel.ThreadContext.MastodonContext(
                    domain: status.domain,
                    contextID: status.id,
                    replyToStatusID: status.replyToStatusID
                )
            }
            
            guard let mastodonContext = _mastodonContext else {
                await enter(state: PrepareFail.self)
                return
            }
            
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch cached contextID: \(mastodonContext.contextID)")
            viewModel.threadContext.value = .mastodon(mastodonContext)
            await enter(state: Idle.self)
            await enter(state: Loading.self)
        }
        
        @MainActor
        func enter(state: StatusThreadViewModel.LoadThreadState.Type) {
            stateMachine?.enter(state)
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

        var needsFallback = false
        
        var maxID: String?          // v1
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

            guard let viewModel = viewModel else { return }
            guard let threadContext = viewModel.threadContext.value else {
                assertionFailure()
                return
            }
            
            Task {
                switch threadContext {
                case .twitter(let twitterConversation):
                    if needsFallback {
                        let nodes = await fetchFallback(twitterConversation: twitterConversation)
                        await append(nodes: nodes)
                    } else {
                        let nodes = await fetch(twitterConversation: twitterConversation)
                        await append(nodes: nodes)
                    }
                case .mastodon(let mastodonContext):
                    let response = await fetch(mastodonContext: mastodonContext)
                    await append(response: response)
                }
            }
        }

        // TODO: group into `StatusListFetchViewModel`
        // fetch thread via V2 API
        func fetch(
            twitterConversation: StatusThreadViewModel.ThreadContext.TwitterConversation
        ) async -> [TwitterStatusThreadLeafViewModel.Node] {
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return [] }
            guard case let .twitter(authenticationContext) = viewModel.authContext.authenticationContext,
                  let conversationID = twitterConversation.conversationID
            else {
                await enter(state: Fail.self)
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
                    nextToken: nextToken,
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
                    await enter(state: Idle.self)
                } else {
                    await enter(state: NoMore.self)
                }
                
                return nodes
            } catch let error as Twitter.API.Error.ResponseError where error.twitterAPIError == .rateLimitExceeded {
                self.needsFallback = true
                stateMachine.enter(Idle.self)
                stateMachine.enter(Loading.self)
                return []
            } catch {
                await enter(state: Fail.self)
                return []
            }
        }
        
        // fetch thread via V1 API
        func fetchFallback(
            twitterConversation: StatusThreadViewModel.ThreadContext.TwitterConversation
        ) async -> [TwitterStatusThreadLeafViewModel.Node] {
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return [] }
            guard case let .twitter(authenticationContext) = viewModel.authContext.authenticationContext,
                  let _ = twitterConversation.conversationID
            else {
                await enter(state: Fail.self)
                return []
            }
            
            do {
                let response = try await viewModel.context.apiService.searchTwitterStatusV1(
                    conversationRootTweetID: twitterConversation.statusID,
                    authorUsername: twitterConversation.authorUsername,
                    maxID: maxID,
                    authenticationContext: authenticationContext
                )
                let nodes = TwitterStatusThreadLeafViewModel.Node.children(
                    of: twitterConversation.statusID,
                    from: response.value
                )
                
                var hasMore = false
                if let nextResult = response.value.searchMetadata.nextResults,
                   let components = URLComponents(string: nextResult),
                   let maxID = components.queryItems?.first(where: { $0.name == "max_id" })?.value,
                   maxID != self.maxID
                {
                    self.maxID = maxID
                    hasMore = !(response.value.statuses ?? []).isEmpty
                }
                
                if hasMore {
                    await enter(state: Idle.self)
                } else {
                    await enter(state: NoMore.self)
                }
                
                return nodes
            } catch let error as Twitter.API.Error.ResponseError where error.twitterAPIError == .rateLimitExceeded {
                self.needsFallback = true
                stateMachine.enter(Idle.self)
                stateMachine.enter(Loading.self)
                return []
            } catch {
                await enter(state: Fail.self)
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
        
        struct MastodonContextResponse {
            let domain: String
            let ancestorNodes: [MastodonStatusThreadViewModel.Node]
            let descendantNodes: [MastodonStatusThreadViewModel.Node]
        }
        
        // fetch thread
        func fetch(
            mastodonContext: StatusThreadViewModel.ThreadContext.MastodonContext
        ) async -> MastodonContextResponse {
            guard let viewModel = viewModel else {
                return MastodonContextResponse(
                    domain: "",
                    ancestorNodes: [],
                    descendantNodes: []
                )
            }
            guard case let .mastodon(authenticationContext) = viewModel.authContext.authenticationContext
            else {
                await enter(state: Fail.self)
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
                let ancestorNodes = MastodonStatusThreadViewModel.Node.replyToThread(
                    for: mastodonContext.replyToStatusID,
                    from: response.value.ancestors
                )
                let descendantNodes = MastodonStatusThreadViewModel.Node.children(
                    of: mastodonContext.contextID,
                    from: response.value.descendants
                )

                // update state
                await enter(state: NoMore.self)
                
                return MastodonContextResponse(
                    domain: mastodonContext.domain,
                    ancestorNodes: ancestorNodes,
                    descendantNodes: descendantNodes
                )
            } catch {
                await enter(state: Fail.self)
                return MastodonContextResponse(
                    domain: "",
                    ancestorNodes: [],
                    descendantNodes: []
                )
            }
        }
        
        @MainActor
        func enter(state: StatusThreadViewModel.LoadThreadState.Type) {
            stateMachine?.enter(state)
        }
    }
    
    class Fail: StatusThreadViewModel.LoadThreadState {
        override var name: String { "Fail" }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }

        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
        }
    }
    
    class NoMore: StatusThreadViewModel.LoadThreadState {
        override var name: String { "NoMore" }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }

        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
        }
    }
    
}
