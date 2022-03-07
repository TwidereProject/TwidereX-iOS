//
//  TwitterUserOwnedListViewModel+State.swift
//  
//
//  Created by MainasuK on 2022-3-1.
//

import os.log
import Foundation
import GameplayKit

extension TwitterUserOwnedListViewModel {
    class State: GKState, NamingState {
        let logger = Logger(subsystem: "TwitterOwnedListViewModel.State", category: "StateMachine")
        let id = UUID()

        var name: String {
            String(describing: Self.self)
        }
        weak var viewModel: TwitterUserOwnedListViewModel?
        
        init(viewModel: TwitterUserOwnedListViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            let previousState = previousState as? TwitterUserOwnedListViewModel.State
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] enter \(self.name), previous: \(previousState?.name  ?? "<nil>")")
        }
        
        @MainActor
        func enter(state: TwitterUserOwnedListViewModel.State.Type) {
            stateMachine?.enter(state)
        }
        
        deinit {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] \(self.name)")
        }
    }
}

extension TwitterUserOwnedListViewModel.State {
    class Initial: TwitterUserOwnedListViewModel.State {
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
    
    class Reloading: TwitterUserOwnedListViewModel.State {
        
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
            viewModel.fetchedResultController.reset()

            stateMachine.enter(Loading.self)
        }
    }
    
    class Loading: TwitterUserOwnedListViewModel.State {
        
        var nextToken: String? = nil
        
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
            
            switch previousState {
            case is Reloading:
                nextToken = nil
            default:
                break
            }

            guard let user = viewModel.user,
                  case let .twitter(authenticationContext) = viewModel.context.authenticationService.activeAuthenticationContext
            else {
                stateMachine.enter(Fail.self)
                return
            }

            let nextToken = nextToken
            
            // The state machine needs guard the Task is re-entry issue-free
            Task {
                do {
                    let response = try await viewModel.context.apiService.twitterUserOwnedLists(
                        user: user,
                        query: .init(nextToken: nextToken),
                        authenticationContext: authenticationContext
                    )
                    let ids = response.value.data?.map { $0.id } ?? []
                    if let nextToken = response.value.meta.nextToken {
                        self.nextToken = nextToken
                        await enter(state: Idle.self)
                    } else if response.value.meta.resultCount == 0 {
                        await enter(state: NoMore.self)
                    } else {
                        await enter(state: NoMore.self)
                    }
                    viewModel.fetchedResultController.append(ids: ids)
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch user timeline fail: \(error.localizedDescription)")
                    await enter(state: Fail.self)
                }
            }   // end Task
        }   // end func
    }
    
    class Fail: TwitterUserOwnedListViewModel.State {
        
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
            guard let _ = viewModel, let stateMachine = stateMachine else { return }
            
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: retry loading 3s later…", ((#file as NSString).lastPathComponent), #line, #function)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: retry loading", ((#file as NSString).lastPathComponent), #line, #function)
                stateMachine.enter(Loading.self)
            }
        }
    }
    
    class Idle: TwitterUserOwnedListViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class NoMore: TwitterUserOwnedListViewModel.State {
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
