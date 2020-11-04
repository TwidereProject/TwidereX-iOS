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
            
            viewModel.fetchLatest()
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log("%{public}s[%{public}ld], %{public}s: fetch user timeline latest response error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        stateMachine.enter(Fail.self)
                    case .finished:
                        stateMachine.enter(Idle.self)
                    }
                } receiveValue: { response in
                    let tweetIDs = response.value.map { $0.idStr }
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
                    let oldTweetIDs = viewModel.tweetIDs.value
                    let newTweets = response.value.filter { !oldTweetIDs.contains($0.idStr) }
                    let newTweetIDs = newTweets.map { $0.idStr }
                    
                    var tweetIDs: [Twitter.Entity.Tweet.ID] = []
                    for tweetID in oldTweetIDs {
                        guard !tweetIDs.contains(tweetID) else { continue }
                        tweetIDs.append(tweetID)
                    }
                    for tweetID in newTweetIDs {
                        guard !tweetIDs.contains(tweetID) else { continue }
                        tweetIDs.append(tweetID)
                    }
                    viewModel.tweetIDs.value = tweetIDs
                    
                    // TODO: add video & GIF
                    let hasMedia = newTweets.contains(where: { tweet in
                        guard let media = tweet.extendedEntities?.media else { return false }
                        return media.contains(where: { $0.type == "photo" })
                    })
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
