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
import TwitterAPI

extension UserMediaTimelineViewModel {
    class State: GKState {
        weak var viewModel: UserMediaTimelineViewModel?
        
        init(viewModel: UserMediaTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            viewModel?.stateMachinePublisher.send(self)
        }
    }
}

extension UserMediaTimelineViewModel.State {
    class Initial: UserMediaTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            guard viewModel.userID.value != nil else { return false }
            return stateClass == Reloading.self
        }
    }
    
    class Reloading: UserMediaTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            viewModel.tweetIDs.value = []
            viewModel.items.value = []
            
            let userID = viewModel.userID.value
            viewModel.fetchLatest()
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log("%{public}s[%{public}ld], %{public}s: fetch user timeline latest response error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        stateMachine.enter(Fail.self)
                    case .finished:
                        stateMachine.enter(Idle.self)
                    }
                } receiveValue: { response in
                    guard viewModel.userID.value == userID else { return }
                    let pagingTweetIDs = response.value
                        .map { $0.idStr }
                    let tweetIDs = response.value
                        .filter { ($0.retweetedStatus ?? $0).user.idStr == userID }
                        .map { $0.idStr }
                    viewModel.pagingTweetIDs.value = pagingTweetIDs
                    viewModel.tweetIDs.value = tweetIDs
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: UserMediaTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reloading.self || stateClass == LoadingMore.self
        }
    }
    
    class Idle: UserMediaTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reloading.self || stateClass == LoadingMore.self
        }
    }
    
    class LoadingMore: UserMediaTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            let userID = viewModel.userID.value
            viewModel.loadMore()
                .receive(on: DispatchQueue.main)
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
                    
                    var pagingTweetIDs = viewModel.pagingTweetIDs.value
                    var tweetIDs = viewModel.tweetIDs.value
                    
                    var hasMedia = false
                    for tweet in response.value {
                        guard let media = (tweet.retweetedStatus ?? tweet).extendedEntities?.media,
                              media.contains(where: { $0.type == "photo" }) else {
                            continue
                        }
                        hasMedia = true
                        
                        let tweetID = tweet.idStr
                        if !pagingTweetIDs.contains(tweetID) && (tweet.retweetedStatus ?? tweet).user.idStr == userID {
                            pagingTweetIDs.append(tweetID)
                        }
                        if !tweetIDs.contains(tweetID) {
                            tweetIDs.append(tweetID)
                        }
                    }
                    
                    viewModel.pagingTweetIDs.value = pagingTweetIDs
                    viewModel.tweetIDs.value = tweetIDs
                    
                    if !hasMedia {
                        stateMachine.enter(NoMore.self)
                    } else {
                        stateMachine.enter(Idle.self)
                    }
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class NoMore: UserMediaTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reloading.self
        }
    }
    
}
