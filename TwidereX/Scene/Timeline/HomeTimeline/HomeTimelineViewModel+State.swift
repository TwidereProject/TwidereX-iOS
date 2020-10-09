//
//  HomeTimelineViewModel+State.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-9.
//

import os.log
import Foundation
import GameplayKit

extension HomeTimelineViewModel {
    class State: GKState {
        weak var viewModel: HomeTimelineViewModel?
        
        init(viewModel: HomeTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            viewModel?.stateMachinePublisher.send(self)
        }
    }
}

extension HomeTimelineViewModel.State {
    class Initial: HomeTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reloading.self
        }
    }
    
    class Reloading: HomeTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let twitterAuthentication = viewModel.currentTwitterAuthentication.value,
                  let authorization = try? twitterAuthentication.authorization(appSecret: AppSecret.shared) else {
                assertionFailure()
                return
            }
            
            viewModel.context.apiService.twitterHomeTimeline(authorization: authorization)
                .delay(for: .seconds(1), scheduler: DispatchQueue.main)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        // TODO: handle error
                        viewModel.isFetchingLatestTimeline.value = false
                        os_log("%{public}s[%{public}ld], %{public}s: fetch tweets failed. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    case .finished:
                        // handle isFetchingLatestTimeline in fetch controller delegate
                        break
                    }
                    
                    stateMachine.enter(Idle.self)
                    
                } receiveValue: { tweets in
                    // fallback path when no new tweets. Note: snapshot average calculate time is 3.0s
                    // FIXME: use notification to stop refresh conrol and avoid this workaround
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        viewModel.isFetchingLatestTimeline.value = false
                    }
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: HomeTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reloading.self || stateClass == LoadingMore.self
        }
    }
    
    class Idle: HomeTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reloading.self || stateClass == LoadingMore.self
        }
    }
    
    class LoadingMore: HomeTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
//            viewModel.loadMore()
//                .sink { [weak self] completion in
//                    switch completion {
//                    case .failure(let error):
//                        stateMachine.enter(Fail.self)
//                    case .finished:
//                        stateMachine.enter(Idle.self)
//                    }
//                } receiveValue: { [weak self] response in
//                    let newTweetIds = response.value.map { $0.idStr }
//                    let idSet = Set(viewModel.userTimelineTweetIDs.value).union(newTweetIds)
//                    viewModel.userTimelineTweetIDs.value = Array(idSet)
//                }
//                .store(in: &viewModel.disposeBag)
        }
    }
    
    class NoMore: HomeTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reloading.self
        }
    }
}
