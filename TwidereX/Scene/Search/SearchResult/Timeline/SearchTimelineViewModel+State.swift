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
import TwitterSDK

extension SearchTimelineViewModel {
    class State: GKState {
        weak var viewModel: SearchTimelineViewModel?
        
        init(viewModel: SearchTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension SearchTimelineViewModel.State {
    class Initial: SearchTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Idle.self || stateClass == Reset.self || stateClass == Loading.self
        }
    }
    
    class Idle: SearchTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reset.self || stateClass == Loading.self
        }
    }
    
    class Reset: SearchTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)

            viewModel?.statusRecordFetchedResultController.reset()
            stateMachine?.enter(Loading.self)
        }
    }
    
    class Loading: SearchTimelineViewModel.State {
        let logger = Logger(subsystem: "SearchTimelineViewModel.State", category: "StateMachine")
//        var error: Error?
//
//        var needsFallback = false
//        var previousSearchText = ""
        
        // var maxID: String?          // v1 fallback
        // var nextToken: String?      // v2
        
        var nextInput: StatusListFetchViewModel.Input?
        var currentTask: Task<Void, Error>?
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self
                || stateClass == Reset.self
                || stateClass == Idle.self
                || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            if previousState is Reset {
                nextInput = nil
                currentTask?.cancel()
            }
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let authenticationContext = viewModel.context.authenticationService.activeAuthenticationContext.value
            else {
                stateMachine.enter(Fail.self)
                return
            }
            
            let searchText = viewModel.searchText
            
            if nextInput == nil {
                nextInput = {
                    switch authenticationContext {
                    case .twitter(let authenticationContext):
                        return StatusListFetchViewModel.Input(
                            fetchContext: .twitter(.init(
                                authenticationContext: authenticationContext,
                                searchText: searchText,
                                maxID: nil,
                                nextToken: nil,
                                count: 50,
                                excludeReplies: false,
                                userIdentifier: nil
                            ))
                        )
                    case .mastodon(let authenticationContext):
                        return StatusListFetchViewModel.Input(
                            fetchContext: .mastodon(.init(
                                authenticationContext: authenticationContext,
                                maxID: nil,
                                count: 50,
                                excludeReplies: false,
                                excludeReblogs: false,
                                onlyMedia: false,
                                userIdentifier: nil
                            ))
                        )
                    }
                }()
            }
            
            guard let input = nextInput else {
                stateMachine.enter(Fail.self)
                return
            }
            
            currentTask?.cancel()
            currentTask = Task {
                do {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch…")
                    let output = try await StatusListFetchViewModel.searchTimeline(context: viewModel.context, input: input)
                    
                    // check cancel
                    guard !Task.isCancelled else {
                        return
                    }
                    
                    nextInput = output.nextInput
                    if output.hasMore {
                        stateMachine.enter(Idle.self)
                    } else {
                        stateMachine.enter(NoMore.self)
                    }
                    
                    switch output.result {
                    case .twitterV2(let statuses):
                        let statusIDs = statuses.map { $0.id }
                        viewModel.statusRecordFetchedResultController.twitterStatusFetchedResultController.append(statusIDs: statusIDs)
                    case .twitter:
                        // not use v1 API here
                        assertionFailure()
                        return
                    case .mastodon(let statuses):
                        let statusIDs = statuses.map { $0.id }
                        viewModel.statusRecordFetchedResultController.mastodonStatusFetchedResultController.append(statusIDs: statusIDs)
                    }
                }
            }   // end currentTask = Task { … }
            
//            if !needsFallback {
//                loading(viewModel: viewModel, twitterAuthenticationBox: activeTwitterAuthenticationBox, stateMachine: stateMachine)
//            } else {
//                loadingFallback(viewModel: viewModel, twitterAuthenticationBox: activeTwitterAuthenticationBox, stateMachine: stateMachine)
//            }
        }   // end func didEnter(from:)
        
//        func loading(
//            viewModel: SearchTimelineViewModel,
//            twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox,
//            stateMachine: GKStateMachine
//        ) {
//            let searchText = viewModel.searchText.value + " (-is:retweet)"
//            guard !searchText.isEmpty, searchText.count < 512 else {
//                error = SearchTimelineViewModel.SearchTimelineError.invalidSearchText
//                // TODO: notify error
//                stateMachine.enter(Fail.self)
//                return
//            }
//            if searchText != previousSearchText {
//                reset(searchText: searchText)
//            }
//
//            viewModel.context.apiService.tweetsRecentSearch(
//                searchText: searchText,
//                nextToken: nextToken,
//                twitterAuthenticationBox: twitterAuthenticationBox
//            )
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                guard let self = self else { return }
//                switch completion {
//                case .failure(let error):
//                    os_log("%{public}s[%{public}ld], %{public}s: search %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, searchText, error.localizedDescription)
//                    if let responseError = error as? Twitter.API.Error.ResponseError,
//                       case .rateLimitExceeded = responseError.twitterAPIError {
//                        self.needsFallback = true
//                        stateMachine.enter(Idle.self)
//                        stateMachine.enter(Loading.self)
//                    } else {
//                        stateMachine.enter(Fail.self)
//                        self.error = error
//                    }
//                case .finished:
//                    break
//                }
//            } receiveValue: { [weak self] response in
//                guard let self = self else { return }
//                let content = response.value
//                os_log("%{public}s[%{public}ld], %{public}s: search %s success. results count %ld", ((#file as NSString).lastPathComponent), #line, #function, searchText, content.meta.resultCount)
//
//                self.nextToken = content.meta.nextToken
//
//                var hasNewTweetAppend = false
//                let newTweets = content.data?.compactMap { $0 } ?? []
//                var tweetIDs: [Twitter.Entity.Tweet.ID] = viewModel.tweetFetchedResultsController.tweetIDs.value
//                for tweet in newTweets {
//                    guard !tweetIDs.contains(tweet.id) else { continue }
//                    tweetIDs.append(tweet.id)
//                    hasNewTweetAppend = true
//                }
//
//                if hasNewTweetAppend {
//                    stateMachine.enter(Idle.self)
//                } else {
//                    stateMachine.enter(NoMore.self)
//                }
//                viewModel.tweetFetchedResultsController.tweetIDs.value = tweetIDs
//            }
//            .store(in: &viewModel.disposeBag)
//        }
        
//        func loadingFallback(
//            viewModel: SearchTimelineViewModel,
//            twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox,
//            stateMachine: GKStateMachine
//        ) {
//            let searchText = viewModel.searchText.value
//            guard !searchText.isEmpty, searchText.count < 500 else {
//                error = SearchTimelineViewModel.SearchTimelineError.invalidSearchText
//                // TODO: notify error
//                stateMachine.enter(Fail.self)
//                return
//            }
//            if searchText != previousSearchText {
//                reset(searchText: searchText)
//            }
//
//            viewModel.context.apiService.tweetsSearch(
//                searchText: searchText,
//                maxID: maxID,
//                twitterAuthenticationBox: twitterAuthenticationBox
//            )
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                guard let self = self else { return }
//                switch completion {
//                case .failure(let error):
//                    os_log("%{public}s[%{public}ld], %{public}s: search %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, searchText, error.localizedDescription)
//                    self.error = error
//                    stateMachine.enter(Fail.self)
//                case .finished:
//                    break
//                }
//            } receiveValue: { [weak self] response in
//                guard let self = self else { return }
//
//                var hasNewTweetAppend = false
//                let newTweets = response.value.statuses ?? []
//                var tweetIDs: [Twitter.Entity.Tweet.ID] = viewModel.tweetFetchedResultsController.tweetIDs.value
//                for tweet in newTweets {
//                    guard !tweetIDs.contains(tweet.idStr) else { continue }
//                    tweetIDs.append(tweet.idStr)
//                    hasNewTweetAppend = true
//                }
//
//                let components = URLComponents(string: response.value.searchMetadata.nextResults)
//                if let maxID = components?.queryItems?.first(where: { $0.name == "max_id" })?.value {
//                    self.maxID = maxID
//                }
//
//                if hasNewTweetAppend {
//                    stateMachine.enter(Idle.self)
//                } else {
//                    stateMachine.enter(NoMore.self)
//                }
//                viewModel.tweetFetchedResultsController.tweetIDs.value = tweetIDs
//            }
//            .store(in: &viewModel.disposeBag)
//        }
        
    }   // end class Loading: SearchTimelineViewModel.State { … }

    
    class Fail: SearchTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reset.self || stateClass == Loading.self
        }
    }
    
    class NoMore: SearchTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reset.self || stateClass == Loading.self
        }
    }
}
