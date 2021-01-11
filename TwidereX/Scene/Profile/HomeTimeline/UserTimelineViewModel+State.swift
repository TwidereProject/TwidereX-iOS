//
//  UserTimelineViewModel+State.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-30.
//

import os.log
import Foundation
import GameplayKit
import TwitterAPI

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
            guard viewModel.userID.value != nil else { return false }
            return stateClass == Reloading.self
        }
    }
    
    class Reloading: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self || stateClass == NoMore.self ||
                stateClass == NotAuthorized.self || stateClass == Blocked.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            viewModel.tweetIDs.value = []
            
            let userID = viewModel.userID.value
            viewModel.fetchLatest()
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log("%{public}s[%{public}ld], %{public}s: fetch user timeline latest response error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        if NotAuthorized.canEnter(for: error) {
                            stateMachine.enter(NotAuthorized.self)
                        } else if Blocked.canEnter(for: error) {
                            stateMachine.enter(Blocked.self)
                        } else {
                            stateMachine.enter(Fail.self)
                        }
                    case .finished:
                        break
                    }
                } receiveValue: { response in
                    guard viewModel.userID.value == userID else { return }
                    let tweetIDs = response.value.map { $0.idStr }
                    
                    if tweetIDs.isEmpty {
                        stateMachine.enter(NoMore.self)
                    } else {
                        stateMachine.enter(Idle.self)
                    }
                    viewModel.tweetIDs.value = tweetIDs
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reloading.self || stateClass == LoadingMore.self
        }
    }
    
    class Idle: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reloading.self || stateClass == LoadingMore.self
        }
    }
    
    class LoadingMore: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            let userID = viewModel.userID.value
            viewModel.loadMore()
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        stateMachine.enter(Fail.self)
                        os_log("%{public}s[%{public}ld], %{public}s: load more fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    case .finished:
                        break
                    }
                } receiveValue: { response in
                    guard viewModel.userID.value == userID else { return }
                    
                    var hasNewTweets = false
                    var tweetIDs = viewModel.tweetIDs.value
                    for tweet in response.value {
                        if !tweetIDs.contains(tweet.idStr) {
                            hasNewTweets = true
                            tweetIDs.append(tweet.idStr)
                        }
                    }
                    
                    if !hasNewTweets {
                        stateMachine.enter(NoMore.self)
                    } else {
                        stateMachine.enter(Idle.self)
                    }

                    viewModel.tweetIDs.value = tweetIDs
                }
                .store(in: &viewModel.disposeBag)
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
            return stateClass == Reloading.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel else { return }

            // trigger items update
            viewModel.tweetIDs.value = []
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
            return stateClass == Reloading.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel else { return }
            
            // trigger items update
            viewModel.tweetIDs.value = []
        }
    }
    
    class NoMore: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reloading.self
        }
    }
}
