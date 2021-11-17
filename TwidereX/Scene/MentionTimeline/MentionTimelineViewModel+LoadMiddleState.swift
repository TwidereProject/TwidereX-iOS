//
//  MentionTimelineViewModel+LoadMiddleState.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-3.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit
import CoreData
import CoreDataStack

extension MentionTimelineViewModel {
    class LoadMiddleState: GKState {
        weak var viewModel: MentionTimelineViewModel?
        let upperTimelineIndexObjectID: NSManagedObjectID
        
        init(viewModel: MentionTimelineViewModel, upperTimelineIndexObjectID: NSManagedObjectID) {
            self.viewModel = viewModel
            self.upperTimelineIndexObjectID = upperTimelineIndexObjectID
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            var dict = viewModel.loadMiddleSateMachineList.value
            dict[upperTimelineIndexObjectID] = stateMachine
            viewModel.loadMiddleSateMachineList.value = dict    // trigger value change
        }
    }
}

extension MentionTimelineViewModel.LoadMiddleState {
    
    class Initial: MentionTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: MentionTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // guard let viewModel = viewModel else { return false }
            return stateClass == Success.self || stateClass == Fail.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
//            guard let twitterAuthenticationBox = viewModel.context.authenticationService.activeTwitterAuthenticationBox.value else {
//                assertionFailure()
//                return
//            }
//
//            guard let timelineIndex = (viewModel.fetchedResultsController.fetchedObjects ?? []).first(where: { $0.objectID == upperTimelineIndexObjectID }),
//                  let tweet = timelineIndex.tweet else {
//                stateMachine.enter(Fail.self)
//                return
//            }
//            let tweetIDs = (viewModel.fetchedResultsController.fetchedObjects ?? []).compactMap { timelineIndex in
//                timelineIndex.tweet?.id
//            }
//
//            // TODO: only set large count when using Wi-Fi
//            let maxID = tweet.id
//            viewModel.context.apiService.twitterMentionTimeline(count: 20, maxID: maxID, twitterAuthenticationBox: twitterAuthenticationBox)
//                .delay(for: .seconds(1), scheduler: DispatchQueue.main)
//                .receive(on: DispatchQueue.main)
//                .sink { completion in
//                    switch completion {
//                    case .failure(let error):
//                        // TODO: handle error
//                        os_log("%{public}s[%{public}ld], %{public}s: fetch tweets failed. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//                        stateMachine.enter(Fail.self)
//                    case .finished:
//                        break
//                    }
//                } receiveValue: { response in
//                    let tweets = response.value
//                    let newTweets = tweets.filter { !tweetIDs.contains($0.idStr) }
//                    os_log("%{public}s[%{public}ld], %{public}s: load %{public}ld tweets, %{public}%ld new tweets", ((#file as NSString).lastPathComponent), #line, #function, tweets.count, newTweets.count)
//                    if newTweets.isEmpty {
//                        stateMachine.enter(Fail.self)
//                    } else {
//                        stateMachine.enter(Success.self)
//                    }
//                }
//                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: MentionTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // guard let viewModel = viewModel else { return false }
            return stateClass == Loading.self
        }
    }
    
    class Success: MentionTimelineViewModel.LoadMiddleState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // guard let viewModel = viewModel else { return false }
            return false
        }
    }
    
}
