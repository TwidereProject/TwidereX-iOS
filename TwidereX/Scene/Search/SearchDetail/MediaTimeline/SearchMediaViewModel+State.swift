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
        
        var needsFallback = false
        var previoursSearchText = ""
        
        var maxID: String?          // v1 fallback
        var nextToken: String?      // v2
        
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
            
            if !needsFallback {
                loading(viewModel: viewModel, twitterAuthenticationBox: activeTwitterAuthenticationBox, stateMachine: stateMachine)
            } else {
                loadingFallback(viewModel: viewModel, twitterAuthenticationBox: activeTwitterAuthenticationBox, stateMachine: stateMachine)
            }
        }
        
        func loading(
            viewModel: SearchMediaViewModel,
            twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox,
            stateMachine: GKStateMachine
        ) {
            let _searchText = viewModel.searchText.value
            let searchText = _searchText + " (-is:retweet has:media)"    // TODO: handle video & GIF
            guard !_searchText.isEmpty, searchText.count < 512 else {
                error = SearchMediaViewModel.SearchMediaError.invalidSearchText
                stateMachine.enter(Fail.self)
                return
            }
            if searchText != previoursSearchText {
                reset(searchText: searchText)
            }
            
            viewModel.context.apiService.tweetsRecentSearch(
                searchText: searchText,
                nextToken: nextToken,
                twitterAuthenticationBox: twitterAuthenticationBox
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: search %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, searchText, error.localizedDescription)
                    if let responseError = error as? Twitter.API.Error.ResponseError,
                       case .rateLimitExceeded = responseError.twitterAPIError {
                        self.needsFallback = true
                        stateMachine.enter(Idle.self)
                        stateMachine.enter(Loading.self)
                    } else {
                        stateMachine.enter(Fail.self)
                        self.error = error
                    }
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
        
        func loadingFallback(
            viewModel: SearchMediaViewModel,
            twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox,
            stateMachine: GKStateMachine
        ) {
            let _searchText = viewModel.searchText.value
            let searchText = _searchText + " -filter:retweets filter:media"
            guard !_searchText.isEmpty, searchText.count < 500 else {
                error = SearchTimelineViewModel.SearchTimelineError.invalidSearchText
                // TODO: notify error
                stateMachine.enter(Fail.self)
                return
            }
            if searchText != previoursSearchText {
                reset(searchText: searchText)
            }
            
            viewModel.context.apiService.tweetsSearch(
                searchText: searchText,
                maxID: maxID,
                twitterAuthenticationBox: twitterAuthenticationBox
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: search %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, searchText, error.localizedDescription)
                    self.error = error
                    stateMachine.enter(Fail.self)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                var hasNewTweetAppend = false
                let newTweets = response.value.statuses ?? []
                var tweetIDs: [Twitter.Entity.Tweet.ID] = viewModel.searchMediaTweetIDs.value
                for tweet in newTweets {
                    guard !tweetIDs.contains(tweet.idStr) else { continue }
                    tweetIDs.append(tweet.idStr)
                    hasNewTweetAppend = true
                }
                
                let components = URLComponents(string: response.value.searchMetadata.nextResults)
                if let maxID = components?.queryItems?.first(where: { $0.name == "max_id" })?.value {
                    self.maxID = maxID
                }
                
                if hasNewTweetAppend {
                    stateMachine.enter(Idle.self)
                } else {
                    stateMachine.enter(NoMore.self)
                }
                viewModel.searchMediaTweetIDs.value = tweetIDs
            }
            .store(in: &viewModel.disposeBag)
        }
        
        func reset(searchText: String) {
            maxID = nil
            nextToken = nil
            previoursSearchText = searchText
            viewModel?.searchMediaTweetIDs.value = []
            viewModel?.items.value = []
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
