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
    class State: GKState {
        weak var viewModel: UserTimelineViewModel?
        
        init(viewModel: UserTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension UserTimelineViewModel.State {
    class Initial: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            switch stateClass {
            case is Reloading.Type:
                return viewModel.userIdentifier.value != nil
            case is Suspended.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Reloading: UserTimelineViewModel.State {
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
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            viewModel.statusRecordFetchedResultController.reset()

            stateMachine.enter(Idle.self)
            stateMachine.enter(LoadingMore.self)
        }
    }
    
    class Fail: UserTimelineViewModel.State {
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
        let logger = Logger(subsystem: "UserTimelineViewModel.State", category: "StateMachine")
        
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
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }

            let record = viewModel.statusRecordFetchedResultController.records.value.last
            Task {
                await fetch(anchor: record)
            }
            
//            let userID = viewModel.userID.value
//            viewModel.loadMore()
//                .sink { completion in
//                    switch completion {
//                    case .failure(let error):
//                        stateMachine.enter(Fail.self)
//                        os_log("%{public}s[%{public}ld], %{public}s: load more fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//                    case .finished:
//                        break
//                    }
//                } receiveValue: { response in
//                    guard viewModel.userID.value == userID else { return }
//
//                    var hasNewTweets = false
//                    var tweetIDs = viewModel.tweetIDs.value
//                    for tweet in response.value {
//                        if !tweetIDs.contains(tweet.idStr) {
//                            hasNewTweets = true
//                            tweetIDs.append(tweet.idStr)
//                        }
//                    }
//
//                    if !hasNewTweets {
//                        stateMachine.enter(NoMore.self)
//                    } else {
//                        stateMachine.enter(Idle.self)
//                    }
//
//                    viewModel.tweetIDs.value = tweetIDs
//                }
//                .store(in: &viewModel.disposeBag)
        }
        
        private func fetch(anchor record: StatusRecord?) async {
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            guard let userIdentifier = viewModel.userIdentifier.value,
                  let authenticationContext = viewModel.context.authenticationService.activeAuthenticationContext.value else {
                stateMachine.enter(Fail.self)
                return
            }
            
            let maxID: String? = await {
                guard let record = record else { return nil }
                
                let managedObjectContext = viewModel.context.managedObjectContext
                return await managedObjectContext.perform {
                    switch record {
                    case .twitter(let record):
                        guard let status = record.object(in: managedObjectContext) else { return nil }
                        return status.id
                    case .mastodon(let record):
                        guard let status = record.object(in: managedObjectContext) else { return nil }
                        return status.id
                    }
                }
            }()
            
            if record != nil && maxID == nil {
                stateMachine.enter(Fail.self)
                assertionFailure()
                return
            }
            
            let _input: StatusListFetchViewModel.Input? = {
                switch (userIdentifier, authenticationContext) {
                case (.twitter(let identifier), .twitter(let authenticationContext)):
                    return StatusListFetchViewModel.Input(
                        context: viewModel.context,
                        fetchContext: .twitter(.init(
                            authenticationContext: authenticationContext,
                            maxID: maxID,
                            userIdentifier: identifier
                        ))
                    )
                case (.mastodon(let identifier), .mastodon(let authenticationContext)):
                    return StatusListFetchViewModel.Input(
                        context: viewModel.context,
                        fetchContext: .mastodon(.init(
                            authenticationContext: authenticationContext,
                            maxID: maxID,
                            userIdentifier: identifier
                        ))
                    )
                default:
                    return nil
                }
            }()
            
            guard let input = _input else {
                assertionFailure()
                stateMachine.enter(Fail.self)
                return
            }
            
            do {
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch…")
                let output = try await StatusListFetchViewModel.userTimeline(input: input)
                if output.hasMore {
                    stateMachine.enter(Idle.self)
                } else {
                    stateMachine.enter(NoMore.self)
                }
                switch output.result {
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
        }
    }
        
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
