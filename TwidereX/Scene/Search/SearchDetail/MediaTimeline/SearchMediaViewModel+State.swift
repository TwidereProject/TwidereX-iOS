//
//  SearchMediaViewModel+State.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit
import TwitterAPI

extension SearchMediaViewModel {
    class State: GKState {
        weak var viewModel: SearchMediaViewModel?
        
        init(viewModel: SearchMediaViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            viewModel?.stateMachinePublisher.send(self)
        }
    }
}

extension SearchMediaViewModel.State {
    class Initial: SearchMediaViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Idle.self || stateClass == Loading.self
        }
    }
    
    class Idle: SearchMediaViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: SearchMediaViewModel.State {
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
                error = SearchMediaViewModel.SearchMediaError.invalidAuthorization
                stateMachine.enter(Fail.self)
                return
            }
            let searchText = viewModel.searchText.value + " (-is:retweet has:media)"    // TODO: handle video & GIF
            guard !searchText.isEmpty, searchText.count < 512 else {
                error = SearchMediaViewModel.SearchMediaError.invalidSearchText
                stateMachine.enter(Fail.self)
                return
            }
            if searchText != previoursSearchText {
                nextToken = nil
                previoursSearchText = searchText
                viewModel.searchMediaTweetIDs.value = []
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
                self.nextToken = content.meta.nextToken
                os_log("%{public}s[%{public}ld], %{public}s: search %s success. results count %ld", ((#file as NSString).lastPathComponent), #line, #function, searchText, content.meta.resultCount)
                
                guard content.meta.resultCount > 0 else {
                    stateMachine.enter(NoMore.self)
                    return
                }
                
                    
                let newTweets = content.data?.compactMap { $0 } ?? []
                let oldTweetIDs = viewModel.searchMediaTweetIDs.value
                
                var tweetIDs: [Twitter.Entity.Tweet.ID] = []
                for tweetID in oldTweetIDs {
                    guard !tweetIDs.contains(tweetID) else { continue }
                    tweetIDs.append(tweetID)
                }
                
                for tweet in newTweets {
                    guard !tweetIDs.contains(tweet.id) else { continue }
                    tweetIDs.append(tweet.id)
                }
                
                viewModel.searchMediaTweetIDs.value = tweetIDs
                stateMachine.enter(Idle.self)
            }
            .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: SearchMediaViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class NoMore: SearchMediaViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel else { return }
            guard let diffableDataSource = viewModel.diffableDataSource else { return }
            var snapshot = diffableDataSource.snapshot()
            if snapshot.itemIdentifiers.contains(.bottomLoader) {
                snapshot.deleteItems([.bottomLoader])
                diffableDataSource.apply(snapshot, animatingDifferences: false)
            }
        }
    }
}
