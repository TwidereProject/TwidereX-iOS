//
//  TwitterStatusThreadReplyViewModel+State.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit
import CoreDataStack
import TwitterSDK

extension TwitterStatusThreadReplyViewModel {
    class State: GKState, NamingState {
        weak var viewModel: TwitterStatusThreadReplyViewModel?
        var name: String { "Base" }
        
        init(viewModel: TwitterStatusThreadReplyViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, name, (previousState as? NamingState)?.name ?? previousState?.description ?? "nil")
        }
        
        @MainActor
        func enter(state: TwitterStatusThreadReplyViewModel.State.Type) {
            stateMachine?.enter(state)
        }
        
        @MainActor
        func apply(nodes: [TwitterStatusReplyNode]) {
            self.viewModel?.nodes = nodes
        }
    }
}

extension TwitterStatusThreadReplyViewModel.State {
    class Initial: TwitterStatusThreadReplyViewModel.State {
        override var name: String { "Initial" }
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            guard viewModel.root != nil else { return false }
            
            return stateClass == Prepare.self || stateClass == NoMore.self
        }
    }
    
    class Prepare: TwitterStatusThreadReplyViewModel.State {
        
        let logger = Logger(subsystem: "StatusThreadViewModel.LoadReplyState", category: "StateMachine")

        override var name: String { "Prepare" }
        
        static let throat = 20
        var previousResolvedNodeCount: Int? = nil
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == Idle.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let record = viewModel.root else {
                assertionFailure()
                stateMachine.enter(NoMore.self)
                return
            }
            
            Task {
                var nextState: TwitterStatusThreadReplyViewModel.State.Type?
                var nodes: [TwitterStatusThreadReplyViewModel.TwitterStatusReplyNode] = []
                let managedObjectContext = viewModel.context.backgroundManagedObjectContext
                try await managedObjectContext.performChanges {
                    guard let _status = record.object(in: managedObjectContext) else {
                        assertionFailure()
                        return
                    }
                    let status = _status.repost ?? _status
                    
                    var replyToArray: [TwitterStatus] = []
                    var replyToNext: TwitterStatus? = status.replyTo
                    while let next = replyToNext {
                        replyToArray.append(next)
                        replyToNext = next.replyTo
                    }
                    
                    var replyNodes: [TwitterStatusThreadReplyViewModel.TwitterStatusReplyNode] = []
                    for replyTo in replyToArray {
                        let node = TwitterStatusThreadReplyViewModel.TwitterStatusReplyNode(
                            statusID: replyTo.id,
                            replyToStatusID: replyTo.replyToStatusID,
                            status: .success(.init(objectID: replyTo.objectID))
                        )
                        replyNodes.append(node)
                    }
                    
                    let last = replyToArray.last ?? status
                    if let replyToStatusID = last.replyToStatusID {
                        // have reply to pointer but not resolved
                        // check local database and update relationship
                        do {
                            let request = TwitterStatus.sortedFetchRequest
                            request.fetchLimit = 1
                            request.predicate = TwitterStatus.predicate(id: replyToStatusID)
                            let _replyToStatus = try managedObjectContext.fetch(request).first
                            
                            if let replyToStatus = _replyToStatus {
                                // find replyTo in local database
                                // update the entity
                                last.update(replyTo: replyToStatus)
                                
                                // append entity node
                                let node = TwitterStatusThreadReplyViewModel.TwitterStatusReplyNode(
                                    statusID: replyToStatusID,
                                    replyToStatusID: replyToStatus.replyToStatusID,
                                    status: .success(.init(objectID: replyToStatus.objectID))
                                )
                                replyNodes.append(node)
                                
                                // append next placeholder node
                                if let nextReplyToStatusID = replyToStatus.replyToStatusID {
                                    let nextNode = TwitterStatusThreadReplyViewModel.TwitterStatusReplyNode(
                                        statusID: nextReplyToStatusID,
                                        replyToStatusID: nil,
                                        status: .notDetermined
                                    )
                                    replyNodes.append(nextNode)
                                }
                                
                            } else {
                                // not find replyTo in local database
                                // create notDetermined placeholder node
                                let node = TwitterStatusThreadReplyViewModel.TwitterStatusReplyNode(
                                    statusID: replyToStatusID,
                                    replyToStatusID: nil,
                                    status: .notDetermined
                                )
                                replyNodes.append(node)
                            }

                        } catch {
                            assertionFailure(error.localizedDescription)
                        }   // end do { … } catch { … }
                    }   // end if let replyToStatusID = last.replyToStatusID { … }
                    
                    nodes = replyNodes
                                        
                    let pendingNodes = replyNodes.filter { node in
                        switch node.status {
                        case .notDetermined, .fail:     return true
                        case .success:                  return false
                        }
                    }
                    
                    let _nextState: TwitterStatusThreadReplyViewModel.State.Type
                    if pendingNodes.isEmpty {
                        _nextState = NoMore.self
                    } else {
                        if replyNodes.count > Prepare.throat {
                            // stop reply auto lookup
                            _nextState = Idle.self
                        } else {
                            let resolvedNodeCount = replyNodes.count - pendingNodes.count
                            if let previousResolvedNodeCount = self.previousResolvedNodeCount {
                                if previousResolvedNodeCount == resolvedNodeCount {
                                    _nextState = Fail.self
                                } else {
                                    _nextState = Loading.self
                                }
                            } else {
                                self.previousResolvedNodeCount = resolvedNodeCount
                                _nextState = Loading.self
                            }
                        }
                    }   // end if … else …
                    nextState = _nextState
                }   // end try await managedObjectContext.performChanges
                
                guard let nextState = nextState else {
                    assertionFailure()
                    return
                }
                
                // set nodes before state update
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): prepare reply nodes: \(nodes.debugDescription)")
                await apply(nodes: nodes)

                await enter(state: nextState)
                
            }   // end Task
        }   // end didEnter

    }
    
    class Idle: TwitterStatusThreadReplyViewModel.State {
        override var name: String { "Idle" }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: TwitterStatusThreadReplyViewModel.State {

        let logger = Logger(subsystem: "StatusThreadViewModel.LoadReplyState", category: "StateMachine")
        
        override var name: String { "Loading" }

        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Prepare.self || stateClass == Idle.self || stateClass == Fail.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)

            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard case let .twitter(twitterAuthenticationContext) = viewModel.authContext.authenticationContext else {
                return
            }

            let replyNodes = viewModel.nodes
            let pendingNodes = replyNodes.filter { node in
                switch node.status {
                case .notDetermined, .fail: return true
                case .success:              return false
                }
            }
            
            guard !pendingNodes.isEmpty else {
                stateMachine.enter(NoMore.self)
                return
            }
            
            let statusIDs = pendingNodes.map { $0.statusID }
            
            Task {
                do {
                    // the APIService will persist entities into database
                    _ = try await viewModel.context.apiService.twitterStatus(
                        statusIDs: statusIDs,
                        authenticationContext: twitterAuthenticationContext
                    )
                    
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch reply success: \(statusIDs.debugDescription)")
                    await enter(state: Prepare.self)
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch reply fail: \(error.localizedDescription)")
                    await enter(state: Fail.self)
                    // FIXME: needs retry logic here
                }
            }
        }
        
    }   // end class Loading
    
    class Fail: TwitterStatusThreadReplyViewModel.State {
        override var name: String { "Fail" }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
    }
    
    class NoMore: TwitterStatusThreadReplyViewModel.State {
        override var name: String { "NoMore" }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
    }
    
}
