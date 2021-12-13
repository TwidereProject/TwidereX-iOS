//
//  UserTimelineViewModel+State.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-30.
//

import os.log
import Foundation
import GameplayKit
import TwitterSDK

extension UserTimelineViewModel {
    
    class State: GKState, NamingState {
        
        weak var viewModel: UserTimelineViewModel?
        
        var name: String {
            String(describing: Self.self)
        }
        
        let logger = Logger(subsystem: "UserTimelineViewModel.State", category: "StateMachine")
        let id = UUID()
        
        init(viewModel: UserTimelineViewModel) {
            self.viewModel = viewModel
            super.init()
            
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] \(self.name)")
        }
        
        @MainActor
        func enter(state: UserTimelineViewModel.State.Type) {
            stateMachine?.enter(state)
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            let previousState = previousState as? UserTimelineViewModel.State
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] enter \(self.name), previous: \(previousState?.name  ?? "<nil>")")
        }
        
        deinit {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(self.id.uuidString)] \(self.name)")
        }
    }
}

extension UserTimelineViewModel.State {
    class Initial: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            switch stateClass {
            case is Reloading.Type:
                return viewModel.userIdentifier != nil
            case is Suspended.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
        }
    }
    
    class Reloading: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Fail.Type:
                return true
            case is Idle.Type, is LoadingMore.Type:
                return true
            case is NotAuthorized.Type, is Blocked.Type:
                return true
            case is Suspended.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            viewModel.statusRecordFetchedResultController.reset()

            stateMachine.enter(LoadingMore.self)
        }
    }
    
    class Fail: UserTimelineViewModel.State {

        var failureCount = 0
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            case is LoadingMore.Type:
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): get failureCount limit. Not allow enter State.LoadingMore")
                return failureCount < 10        // prevent retry infinity loop
            case is Suspended.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            failureCount += 1
        }
        
        override func willExit(to nextState: GKState) {
            super.willExit(to: nextState)
            
            switch nextState {
            case is Reloading:
                failureCount = 0        // reset count
            default:
                break
            }
        }
    }
    
    class Idle: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is LoadingMore.Type:
                return true
            case is Suspended.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class LoadingMore: UserTimelineViewModel.State {
        
        var nextInput: StatusListFetchViewModel.Input?
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Fail.Type:
                return true
            case is Idle.Type:
                return true
            case is NoMore.Type:
                return true
            case is NotAuthorized.Type, is Blocked.Type:
                return true
            case is Suspended.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)

            // reset when reloading
            switch previousState {
            case is Reloading:
                nextInput = nil
            default:
                break
            }
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            guard let userIdentifier = viewModel.userIdentifier,
                  let authenticationContext = viewModel.context.authenticationService.activeAuthenticationContext.value
            else {
                stateMachine.enter(Fail.self)
                return
            }
            
            if nextInput == nil {
                nextInput = {
                    switch (userIdentifier, authenticationContext) {
                    case (.twitter(let identifier), .twitter(let authenticationContext)):
                        return StatusListFetchViewModel.Input(
                            fetchContext: .twitter(.init(
                                authenticationContext: authenticationContext,
                                searchText: nil,
                                maxID: nil,
                                nextToken: nil,
                                count: 50,
                                excludeReplies: false,
                                onlyMedia: false,
                                userIdentifier: identifier
                            ))
                        )
                    case (.mastodon(let identifier), .mastodon(let authenticationContext)):
                        return StatusListFetchViewModel.Input(
                            fetchContext: .mastodon(.init(
                                authenticationContext: authenticationContext,
                                searchText: nil,
                                offset: nil,
                                maxID: nil,
                                count: 50,
                                excludeReplies: false,
                                excludeReblogs: false,
                                onlyMedia: false,
                                userIdentifier: identifier
                            ))
                        )
                    default:
                        return nil
                    }
                }()
            }

            guard let input = nextInput else {
                stateMachine.enter(Fail.self)
                return
            }
            
            Task {
                do {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch…")
                    let output = try await StatusListFetchViewModel.userTimeline(context: viewModel.context, input: input)
                    
                    nextInput = output.nextInput
                    if output.hasMore {
                        await self.enter(state: Idle.self)
                    } else {
                        await self.enter(state: NoMore.self)
                    }
                    
                    switch output.result {
                    case .twitterV2:
                        // not use v2 API here
                        assertionFailure()
                        return
                    case .twitter(let statuses):
                        let statusIDs = statuses.map { $0.idStr }
                        viewModel.statusRecordFetchedResultController.twitterStatusFetchedResultController.append(statusIDs: statusIDs)
                    case .mastodon(let statuses):
                        let statusIDs = statuses.map { $0.id }
                        viewModel.statusRecordFetchedResultController.mastodonStatusFetchedResultController.append(statusIDs: statusIDs)
                    }
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch success")
                    
                } catch {
                    // FIXME: handle Mastodon timeline error: {"error":"Record not found"}
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch failure: \(error.localizedDescription)")
                    await self.enter(state: Fail.self)
                }
            }   // end Task
        }   // end didEnter(from:)
        
    }   // end class LoadingMore
        
    class NotAuthorized: UserTimelineViewModel.State {
        static func canEnter(for error: Error) -> Bool {
            if let responseError = error as? Twitter.API.Error.ResponseError,
               let twitterAPIError = responseError.twitterAPIError,
               case .notAuthorizedToSeeThisStatus = twitterAPIError {
                return true
            }
            
            return false
        }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            case is Suspended.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel else { return }

            // trigger items update
            viewModel.statusRecordFetchedResultController.reset()
        }
    }
    
    class Blocked: UserTimelineViewModel.State {
        static func canEnter(for error: Error) -> Bool {
            if let responseError = error as? Twitter.API.Error.ResponseError,
               let twitterAPIError = responseError.twitterAPIError,
               case .blockedFromViewingThisUserProfile = twitterAPIError {
                return true
            }
            
            return false
        }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            case is Suspended.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel else { return }
            
            // trigger items update
            viewModel.statusRecordFetchedResultController.reset()
        }
    }
    
    class Suspended: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel else { return }
            
            // trigger items update
            viewModel.statusRecordFetchedResultController.reset()
        }
    }
    
    class NoMore: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            case is NotAuthorized.Type, is Blocked.Type:
                return true
            case is Suspended.Type:
                return true
            default:
                return false
            }
        }
    }
}
