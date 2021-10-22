//
//  UserLikeTimelineViewModel+State.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-4.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit
import TwitterSDK

extension UserLikeTimelineViewModel {
    class State: GKState {
        weak var viewModel: UserLikeTimelineViewModel?
        
        init(viewModel: UserLikeTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension UserLikeTimelineViewModel.State {
    class Initial: UserLikeTimelineViewModel.State {
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
    }
    
    class Reloading: UserLikeTimelineViewModel.State {
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
//            var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, Item>()
//            snapshot.appendSections([.main])
//            snapshot.appendItems([.bottomLoader], toSection: .main)
//            viewModel.diffableDataSource?.apply(snapshot)
//            
//            let userID = viewModel.userID.value
//            viewModel.fetchLatest()
//                .receive(on: DispatchQueue.main)
//                .sink { completion in
//                    switch completion {
//                    case .failure(let error):
//                        os_log("%{public}s[%{public}ld], %{public}s: fetch user timeline latest response error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//                        if NotAuthorized.canEnter(for: error) {
//                            stateMachine.enter(NotAuthorized.self)
//                        } else if Blocked.canEnter(for: error) {
//                            stateMachine.enter(Blocked.self)
//                        } else {
//                            stateMachine.enter(Fail.self)
//                        }
//                    case .finished:
//                        break
//                    }
//                } receiveValue: { response in
//                    guard viewModel.userID.value == userID else { return }
//                    let tweetIDs = response.value.map { $0.idStr }
//
//                    if tweetIDs.isEmpty {
//                        stateMachine.enter(NoMore.self)
//                    } else {
//                        stateMachine.enter(Idle.self)
//                    }
//                    viewModel.tweetIDs.value = tweetIDs
//                }
//                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: UserLikeTimelineViewModel.State {
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
    
    class Idle: UserLikeTimelineViewModel.State {
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
    
    class LoadingMore: UserLikeTimelineViewModel.State {
        let logger = Logger(subsystem: "UserLikeTimelineViewModel.State", category: "StateMachine")

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
                                userIdentifier: identifier
                            ))
                        )
                    case (.mastodon(let identifier), .mastodon(let authenticationContext)):
                        // Mastodon allow fetch oneself like timeline only
                        guard identifier.id == authenticationContext.userID else {
                            return nil
                        }
                        return StatusListFetchViewModel.Input(
                            fetchContext: .mastodon(.init(
                                authenticationContext: authenticationContext,
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
                    let output = try await StatusListFetchViewModel.likeTimeline(context: viewModel.context, input: input)
                    
                    nextInput = output.nextInput
                    if output.hasMore {
                        stateMachine.enter(Idle.self)
                    } else {
                        stateMachine.enter(NoMore.self)
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
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch failure: \(error.localizedDescription)")
                    stateMachine.enter(Fail.self)
                }
            }   // end Task
        }   // end didEnter(from:)
    }   // end class LoadingMore
    
    class NotAuthorized: UserLikeTimelineViewModel.State {
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
    
    class Blocked: UserLikeTimelineViewModel.State {
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
    
    class Suspended: UserLikeTimelineViewModel.State {
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
    
    class NoMore: UserLikeTimelineViewModel.State {
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
