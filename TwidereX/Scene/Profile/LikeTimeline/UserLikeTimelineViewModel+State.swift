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
import TwitterAPI

extension UserLikeTimelineViewModel {
    class State: GKState {
        weak var viewModel: UserLikeTimelineViewModel?
        
        init(viewModel: UserLikeTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            viewModel?.stateMachinePublisher.send(self)
        }
    }
}

extension UserLikeTimelineViewModel.State {
    class Initial: UserLikeTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            guard viewModel.userID.value != nil else { return false }
            return stateClass == Reloading.self
        }
    }
    
    class Reloading: UserLikeTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, Item>()
            snapshot.appendSections([.main])
            snapshot.appendItems([.bottomLoader], toSection: .main)
            viewModel.diffableDataSource?.apply(snapshot)
            
            viewModel.fetchLatest()
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log("%{public}s[%{public}ld], %{public}s: fetch user timeline latest response error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        stateMachine.enter(Fail.self)
                    case .finished:
                        break
                    }
                } receiveValue: { response in
                    let tweetIDs = response.value.map { $0.idStr }
                    viewModel.tweetIDs.value = tweetIDs
                    
                    stateMachine.enter(Idle.self)

                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: UserLikeTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reloading.self || stateClass == LoadingMore.self
        }
    }
    
    class Idle: UserLikeTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reloading.self || stateClass == LoadingMore.self
        }
    }
    
    class LoadingMore: UserLikeTimelineViewModel.State {
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
                        stateMachine.enter(Idle.self)
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
                    
                    if newTweets.isEmpty {
                        stateMachine.enter(NoMore.self)
                    } else {
                        stateMachine.enter(Idle.self)
                    }
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class NoMore: UserLikeTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reloading.self
        }
    }
}
