//
//  ListViewModel+State.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-4.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit
import TwidereCore

extension ListViewModel {
    class State: GKState, NamingState {
        let logger = Logger(subsystem: "ListViewModel.State", category: "StateMachine")
        let id = UUID()

        var name: String {
            String(describing: Self.self)
        }
        weak var viewModel: ListViewModel?
        
        init(viewModel: ListViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            let previousState = previousState as? ListViewModel.State
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] enter \(self.name), previous: \(previousState?.name  ?? "<nil>")")
        }
        
        @MainActor
        func enter(state: ListViewModel.State.Type) {
            stateMachine?.enter(state)
        }
        
        deinit {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] \(self.name)")
        }
    }
}

extension ListViewModel.State {
    class Initial: ListViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let _ = viewModel else { return false }
            switch stateClass {
            case is Reloading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Reloading: ListViewModel.State {
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            // reset
            if viewModel.needsResetBeforeReloading {
                viewModel.fetchedResultController.reset()
            }

            stateMachine.enter(Loading.self)
        }
    }
    
    class Loading: ListViewModel.State {
        
        var nextInput: ListFetchViewModel.List.Input?
        var nonce = UUID()
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Fail.Type:
                return true
            case is Idle.Type:
                return true
            case is NoMore.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            nonce = UUID()
            let nonce = self.nonce
            
            let isReloading: Bool
            switch previousState {
            case is Reloading:
                nextInput = nil
                isReloading = true
            default:
                isReloading = false
            }

            guard let user = viewModel.kind.user else {
                stateMachine.enter(Fail.self)
                return
            }
            let authenticationContext = viewModel.authContext.authenticationContext
            
            if nextInput == nil {
                nextInput = {
                    switch (user, authenticationContext) {
                    case (.twitter(let record), .twitter(let authenticationContext)):
                        let fetchContext = ListFetchViewModel.List.TwitterFetchContext(
                            authenticationContext: authenticationContext,
                            user: record,
                            maxResults: nil,
                            nextToken: nil
                        )
                        let input: ListFetchViewModel.List.Input? = {
                            switch viewModel.kind {
                            case .none:         return nil
                            case .owned:        return .twitterUserOwned(fetchContext)
                            case .subscribed:   return .twitterUserFollowed(fetchContext)
                            case .listed:       return .twitterUserListed(fetchContext)
                            }
                        }()
                        return input
                    case (.mastodon, .mastodon(let authenticationContext)):
                        return .mastodonUserOwned(.init(
                            authenticationContext: authenticationContext
                        ))
                    default:
                        return nil
                    }
                }()
            }
                
            guard let input = nextInput else {
                stateMachine.enter(Fail.self)
                return
            }

            // The state machine needs guard the Task is re-entry issue-free
            Task { @MainActor in
                do {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch…")

                    let output = try await ListFetchViewModel.List.list(api: viewModel.context.apiService, input: input)
                    
                    // check nonce
                    guard nonce == self.nonce else {
                        return
                    }
                    
                    nextInput = output.nextInput
                    if output.hasMore {
                        enter(state: Idle.self)
                    } else {
                        enter(state: NoMore.self)
                    }
                    
                    switch output.result {
                    case .twitter(let lists):
                        let ids = lists.map { $0.id }
                        if isReloading {
                            viewModel.fetchedResultController.twitterListRecordFetchedResultController.update(ids: ids)
                        } else {
                            viewModel.fetchedResultController.twitterListRecordFetchedResultController.append(ids: ids)
                        }
                    case .mastodon(let lists):
                        let ids = lists.map { $0.id }
                        if isReloading {
                            viewModel.fetchedResultController.mastodonListRecordFetchedResultController.update(ids: ids)
                        } else {
                            viewModel.fetchedResultController.mastodonListRecordFetchedResultController.append(ids: ids)
                        }
                    }
                    
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch success")
                    
                    viewModel.retryCount = 0

                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch user timeline fail: \(error.localizedDescription)")
                    enter(state: Fail.self)
                }
            }   // end Task
        }   // end func
    }
    
    class Fail: ListViewModel.State {
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            Task { @MainActor in
                let delay = min(64.0, pow(2.0, Double(viewModel.retryCount)))
                viewModel.retryCount += 1
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: retry loading %.2fs later…", ((#file as NSString).lastPathComponent), #line, #function, delay)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: retry loading", ((#file as NSString).lastPathComponent), #line, #function)
                    stateMachine.enter(Loading.self)
                }
            }   // end Task
        }
    }
    
    class Idle: ListViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class NoMore: ListViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let _ = stateMachine else { return }
            
            // trigger data source update. otherwise, spinner always display
            // viewModel.isSuspended.value = viewModel.isSuspended.value
        }
    }
}
