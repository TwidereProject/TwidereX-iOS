//
//  HomeTimelineViewModel+LoadMiddleState.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-12.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit
import CoreDataStack

extension HomeTimelineViewModel {
    class LoadMiddleState: GKState {
        weak var viewModel: HomeTimelineViewModel?
        let anchorTweetID: Tweet.TweetID
        
        init(viewModel: HomeTimelineViewModel, anchorTweetID: Tweet.TweetID) {
            self.viewModel = viewModel
            self.anchorTweetID = anchorTweetID
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            var dict = viewModel.loadMiddleSateMachineList.value
            dict[anchorTweetID] = stateMachine
            viewModel.loadMiddleSateMachineList.value = dict    // trigger value change
        }
    }
}

extension HomeTimelineViewModel.LoadMiddleState {
    
    class Initial: HomeTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // guard let viewModel = viewModel else { return false }
            return stateClass == Loading.self
        }
    }
    
    class Loading: HomeTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // guard let viewModel = viewModel else { return false }
            return stateClass == Success.self || stateClass == Fail.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let twitterAuthentication = viewModel.currentTwitterAuthentication.value,
                  let authorization = try? twitterAuthentication.authorization(appSecret: AppSecret.shared) else {
                assertionFailure()
                return
            }
            
            let tweetIDs = (viewModel.fetchedResultsController.fetchedObjects ?? []).compactMap { timelineIndex in
                timelineIndex.tweet?.idStr
            }

            // TODO: only set large count when using Wi-Fi
            let maxID = anchorTweetID
            viewModel.context.apiService.twitterHomeTimeline(count: 20, maxID: maxID, authorization: authorization, twitterUserID: twitterAuthentication.userID)
                .delay(for: .seconds(1), scheduler: DispatchQueue.main)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        // TODO: handle error
                        os_log("%{public}s[%{public}ld], %{public}s: fetch tweets failed. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        stateMachine.enter(Fail.self)
                    case .finished:
                        break
                    }
                } receiveValue: { response in
                    let tweets = response.value
                    let newTweets = tweets.filter { !tweetIDs.contains($0.idStr) }
                    os_log("%{public}s[%{public}ld], %{public}s: load %{public}ld tweets, %{public}%ld new tweets", ((#file as NSString).lastPathComponent), #line, #function, tweets.count, newTweets.count)
                    if newTweets.isEmpty {
                        stateMachine.enter(Fail.self)
                    } else {
                        stateMachine.enter(Success.self)
                    }
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: HomeTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // guard let viewModel = viewModel else { return false }
            return stateClass == Loading.self
        }
    }
    
    class Success: HomeTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // guard let viewModel = viewModel else { return false }
            return false
        }
        
//        override func didEnter(from previousState: GKState?) {
//            super.didEnter(from: previousState)
//            guard let viewModel = viewModel else { return }
//
//            var dict = viewModel.loadMiddleSateMachineList.value
//            dict[anchorTweetID] = nil
//            viewModel.loadMiddleSateMachineList.value = dict
//        }
    }
    
}
