//
//  UserMediaTimelineViewModel+State.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-4.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit
import TwitterSDK

extension UserMediaTimelineViewModel {
    class State: GKState {
        weak var viewModel: UserMediaTimelineViewModel?
        
        init(viewModel: UserMediaTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension UserMediaTimelineViewModel.State {
    class Initial: UserMediaTimelineViewModel.State {
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
    
    class Reloading: UserMediaTimelineViewModel.State {
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
            
//            viewModel.tweetIDs.value = []
//            viewModel.items.value = []
            
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
//                    let pagingTweetIDs = response.value
//                        .map { $0.idStr }
//                    let tweetIDs = response.value
//                        .filter { ($0.retweetedStatus ?? $0).user.idStr == userID }
//                        .map { $0.idStr }
//                    
//                    if pagingTweetIDs.isEmpty {
//                        stateMachine.enter(NoMore.self)
//                    } else {
//                        stateMachine.enter(Idle.self)
//                    }
//                    
//                    viewModel.pagingTweetIDs.value = pagingTweetIDs
//                    viewModel.tweetIDs.value = tweetIDs
//                }
//                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: UserMediaTimelineViewModel.State {
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
    
    class Idle: UserMediaTimelineViewModel.State {
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
    
    class LoadingMore: UserMediaTimelineViewModel.State {
        let logger = Logger(subsystem: "UserMediaTimelineViewModel.State", category: "StateMachine")

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
                                count: 200,
                                excludeReplies: true,
                                onlyMedia: true,
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
                                count: 200,
                                excludeReplies: true,
                                excludeReblogs: true,
                                onlyMedia: true,
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
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }
                    
                    switch output.result {
                    case .twitterV2:
                        // not use V2 API here
                        assertionFailure()
                        return
                    case .twitter(let statuses):
                        let statusIDs = statuses
                            .filter { status in
                                guard let media = (status.retweetedStatus ?? status).extendedEntities?.media else { return false }
                                return !media.isEmpty
                            }
                            .map { $0.idStr }
                        viewModel.statusRecordFetchedResultController.twitterStatusFetchedResultController.append(statusIDs: statusIDs)
                    case .mastodon(let statuses):
                        let statusIDs = statuses
                            .filter { status in
                                let mediaAttachments = (status.reblog ?? status).mediaAttachments ?? []
                                return !mediaAttachments.isEmpty
                            }
                            .map { $0.id }
                        viewModel.statusRecordFetchedResultController.mastodonStatusFetchedResultController.append(statusIDs: statusIDs)
                    }
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch success")
                    
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch failure: \(error.localizedDescription)")
                    await enter(state: Fail.self)
                }
            }   // end Task
        }   // end didEnter(from:)
        
        @MainActor
        func enter(state: UserMediaTimelineViewModel.State.Type) {
            stateMachine?.enter(state)
        }
    }   // end func didEnter(from:)
    
    class NotAuthorized: UserMediaTimelineViewModel.State {
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
//            viewModel.pagingTweetIDs.value = []
//            viewModel.tweetIDs.value = []
        }
    }
    
    class Blocked: UserMediaTimelineViewModel.State {
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
//            viewModel.pagingTweetIDs.value = []
//            viewModel.tweetIDs.value = []
        }
    }
    
    class Suspended: UserMediaTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel else { return }
            
            // trigger items update
//            viewModel.pagingTweetIDs.value = []
//            viewModel.tweetIDs.value = []
//            viewModel.items.value = []
        }
    }
    
    class NoMore: UserMediaTimelineViewModel.State {
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
