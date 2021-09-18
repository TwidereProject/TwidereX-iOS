//
//  MentionTimelineViewModel+LoadLatestState.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-3.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit

extension MentionTimelineViewModel {
    class LoadLatestState: GKState {
        weak var viewModel: MentionTimelineViewModel?
        
        init(viewModel: MentionTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            viewModel?.loadLatestStateMachinePublisher.send(self)
        }
    }
}

extension MentionTimelineViewModel.LoadLatestState {
    class Initial: MentionTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: MentionTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
//            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
//            guard let twitterAuthenticationBox = viewModel.context.authenticationService.activeTwitterAuthenticationBox.value else {
//                stateMachine.enter(Fail.self)
//                return
//            }
//            
//            let tweetIDs = (viewModel.fetchedResultsController.fetchedObjects ?? []).compactMap { timelineIndex in
//                timelineIndex.tweet?.id
//            }
//            
//            // TODO: only set large count when using Wi-Fi
//            viewModel.context.apiService.twitterMentionTimeline(count: 200, twitterAuthenticationBox: twitterAuthenticationBox)
//                .delay(for: .seconds(1), scheduler: DispatchQueue.main)
//                .receive(on: DispatchQueue.main)
//                .sink { completion in
//                    switch completion {
//                    case .failure(let error):
//                        // TODO: handle error
//                        viewModel.isFetchingLatestTimeline.value = false
//                        os_log("%{public}s[%{public}ld], %{public}s: fetch tweets failed. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//                    case .finished:
//                        // handle isFetchingLatestTimeline in fetch controller delegate
//                        break
//                    }
//                    
//                    stateMachine.enter(Idle.self)
//                    
//                } receiveValue: { response in
//                    // stop refresher if no new tweets
//                    let tweets = response.value
//                    let newTweets = tweets.filter { !tweetIDs.contains($0.idStr) }
//                    os_log("%{public}s[%{public}ld], %{public}s: load %{public}ld new tweets", ((#file as NSString).lastPathComponent), #line, #function, newTweets.count)
//                    
//                    if newTweets.isEmpty {
//                        viewModel.isFetchingLatestTimeline.value = false
//                    }
//                }
//                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: MentionTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == Idle.self
        }
    }
    
    class Idle: MentionTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
}
