//
//  SearchTimelineViewModel+State.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-29.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit
import TwitterAPI

extension SearchTimelineViewModel {
    class State: GKState {
        weak var viewModel: SearchTimelineViewModel?
        
        init(viewModel: SearchTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            viewModel?.stateMachinePublisher.send(self)
        }
    }
}

extension SearchTimelineViewModel.State {
    class Initial: SearchTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Idle.self || stateClass == Loading.self
        }
    }
    
    class Idle: SearchTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: SearchTimelineViewModel.State {
        var error: Error?
        var previoursSearchText = ""
        var nextToken: String?
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let activeTwitterAuthenticationBox = viewModel.context.authenticationService.activeTwitterAuthenticationBox.value else {
                stateMachine.enter(Fail.self)
                return
            }
            
            let searchText = viewModel.searchText.value + " (-is:retweet)"
            guard !searchText.isEmpty, searchText.count < 512 else {
                error = SearchTimelineViewModel.SearchTimelineError.invalidSearchText
                stateMachine.enter(Fail.self)
                return
            }
            if searchText != previoursSearchText {
                nextToken = nil
                previoursSearchText = searchText
                viewModel.tweetIDs.value = []
                viewModel.items.value = []
            }
            
            viewModel.context.apiService.tweetsRecentSearch(
                searchText: searchText,
                nextToken: nextToken,
                twitterAuthenticationBox: activeTwitterAuthenticationBox
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: search %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, searchText, error.localizedDescription)
                    debugPrint(error)
                    self.error = error
                    stateMachine.enter(Fail.self)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                let content = response.value
                os_log("%{public}s[%{public}ld], %{public}s: search %s success. results count %ld", ((#file as NSString).lastPathComponent), #line, #function, searchText, content.meta.resultCount)

                self.nextToken = content.meta.nextToken
                
                guard content.meta.resultCount > 0 else {
                    stateMachine.enter(NoMore.self)
                    return
                }
                
                let newTweets = content.data?.compactMap { $0 } ?? []
                
                var tweetIDs: [Twitter.Entity.Tweet.ID] = viewModel.tweetIDs.value
                for tweet in newTweets {
                    guard !tweetIDs.contains(tweet.id) else { continue }
                    tweetIDs.append(tweet.id)
                }
                
                viewModel.tweetIDs.value = tweetIDs
                stateMachine.enter(Idle.self)
            }
            .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: SearchTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class NoMore: SearchTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
}
