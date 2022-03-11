//
//  ListUserViewModel+State.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-11.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit
import TwidereCore

extension ListUserViewModel {
    class State: GKState, NamingState {
        let logger = Logger(subsystem: "ListUserViewModel.State", category: "StateMachine")
        let id = UUID()

        var name: String {
            String(describing: Self.self)
        }
        weak var viewModel: ListUserViewModel?
        
        init(viewModel: ListUserViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            let previousState = previousState as? ListUserViewModel.State
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] enter \(self.name), previous: \(previousState?.name  ?? "<nil>")")
        }
        
        @MainActor
        func enter(state: ListUserViewModel.State.Type) {
            stateMachine?.enter(state)
        }
        
        deinit {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] \(self.name)")
        }
    }
}

extension ListUserViewModel.State {
    class Initial: ListUserViewModel.State {
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
    
    class Reloading: ListUserViewModel.State {
        
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
    
    class Loading: ListUserViewModel.State {
        
        var nextInput: UserFetchViewModel.List.Input?
        
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
                nextInput = nil
            default:
                break
            }

            guard let authenticationContext = viewModel.context.authenticationService.activeAuthenticationContext else {
                stateMachine.enter(Fail.self)
                return
            }
            
            let list = viewModel.kind.list

            if nextInput == nil {
                nextInput = {
                    switch (list, authenticationContext) {
                    case (.twitter(let record), .twitter(let authenticationContext)):
                        let fetchContext = UserFetchViewModel.List.TwitterFetchContext(
                            authenticationContext: authenticationContext,
                            list: record,
                            maxResults: nil,
                            nextToken: nil,
                            kind: {
                                switch viewModel.kind {
                                case .members:      return .member
                                case .subscribers:  return .follower
                                }
                            }()
                        )
                        let input = UserFetchViewModel.List.Input.twitter(fetchContext)
                        return input
                    case (.mastodon, .mastodon(let authenticationContext)):
                        assertionFailure("TODO")
                        return nil
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
            Task {
                do {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch…")

                    let output = try await UserFetchViewModel.List.list(api: viewModel.context.apiService, input: input)
                    nextInput = output.nextInput
                    if output.hasMore {
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }

                    switch output.result {
                    case .twitter:
                        assertionFailure("invalid V1 entry")
                    case .twitterV2(let users):
                        let userIDs = users.map { $0.id }
                        viewModel.fetchedResultController.twitterUserFetchedResultsController.append(userIDs: userIDs)
                    case .mastodon(let users):
                        assertionFailure("TODO")
                    }

                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch success")

                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch user list fail: \(error.localizedDescription)")
                    await enter(state: Fail.self)
                }
            }   // end Task
        }   // end func
    }
    
    class Fail: ListUserViewModel.State {
        
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
    
    class Idle: ListUserViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class NoMore: ListUserViewModel.State {
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
