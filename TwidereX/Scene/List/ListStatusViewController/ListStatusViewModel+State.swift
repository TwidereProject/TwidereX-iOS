//
//  ListStatusViewModel+State.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-2.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit

extension ListStatusViewModel {
    class State: GKState, NamingState {
        let logger = Logger(subsystem: "ListStatusViewModel.State", category: "StateMachine")
        let id = UUID()

        var name: String {
            String(describing: Self.self)
        }
        weak var viewModel: ListStatusViewModel?
        
        init(viewModel: ListStatusViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            let previousState = previousState as? ListStatusViewModel.State
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] enter \(self.name), previous: \(previousState?.name  ?? "<nil>")")
        }
        
        @MainActor
        func enter(state: ListStatusViewModel.State.Type) {
            stateMachine?.enter(state)
        }
        
        deinit {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] \(self.name)")
        }
    }
}

extension ListStatusViewModel.State {
    class Initial: ListStatusViewModel.State {
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
    
    class Reloading: ListStatusViewModel.State {
        
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
    
    class Loading: ListStatusViewModel.State {
        
        var nextInput: StatusFetchViewModel.List.Input?

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

            guard let list = viewModel.list,
                  let authenticationContext = viewModel.context.authenticationService.activeAuthenticationContext
            else {
                stateMachine.enter(Fail.self)
                return
            }
            
            if nextInput == nil {
                nextInput = {
                    switch (list, authenticationContext) {
                    case (.twitter(let list), .twitter(let authenticationContext)):
                        return StatusFetchViewModel.List.Input.twitter(.init(
                            authenticationContext: authenticationContext,
                            list: list,
                            maxResults: nil,
                            nextToken: nil
                        ))
                    case (.mastodon(let list), .mastodon(let authenticationContext)):
                        return StatusFetchViewModel.List.Input.mastodon(.init(
                            authenticationContext: authenticationContext,
                            list: list,
                            maxID: nil,
                            limit: nil
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
            Task {
                do {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch…")
                    
                    let output = try await StatusFetchViewModel.List.timeline(context: viewModel.context, input: input)
                    nextInput = output.nextInput
                    if output.hasMore {
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }
                    
                    switch output.result {
                    case .twitterV2(let statuses):
                        let statusIDs = statuses.map { $0.id }
                        viewModel.fetchedResultController.twitterStatusFetchedResultController.append(statusIDs: statusIDs)
                    case .twitter:
                        // no V1 API used here
                        assertionFailure()
                        return
                    case .mastodon(let statuses):
                        let statusIDs = statuses.map { $0.id }
                        viewModel.fetchedResultController.mastodonStatusFetchedResultController.append(statusIDs: statusIDs)
                    }
                    
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch success")
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch failure: \(error.localizedDescription)")
                    await enter(state: Fail.self)
                }
            }   // end Task
        }   // end func
    }
    
    class Fail: ListStatusViewModel.State {
        
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
    
    class Idle: ListStatusViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class NoMore: ListStatusViewModel.State {
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
            // TODO:
        }
    }
}
