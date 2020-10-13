//
//  UserTimelineViewModel+State.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-30.
//

import os.log
import Foundation
import GameplayKit

extension UserTimelineViewModel {
    class State: GKState {
        weak var viewModel: UserTimelineViewModel?
        
        init(viewModel: UserTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            viewModel?.stateMachinePublisher.send(self)
        }
    }
}

extension UserTimelineViewModel.State {
    class Initial: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            guard viewModel.userID.value != nil else { return false }
            return stateClass == Reloading.self
        }
    }
    
    class Reloading: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, TimelineItem>()
            snapshot.appendSections([.main])
            snapshot.appendItems([.bottomLoader], toSection: .main)
            viewModel.diffableDataSource?.apply(snapshot)
            
            viewModel.fetchLatest()
                .sink { [weak self] completion in
                    guard let self = self else { return }
                    switch completion {
                    case .failure(let error):
                        os_log("%{public}s[%{public}ld], %{public}s: fetch user timeline latest response error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        stateMachine.enter(Fail.self)
                    case .finished:
                        stateMachine.enter(Idle.self)
                    }
                } receiveValue: { [weak self] response in
                    guard let self = self else { return }

                    let tweetIDs = response.value.map { $0.idStr }
                    viewModel.userTimelineTweetIDs.value = tweetIDs
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reloading.self || stateClass == LoadingMore.self
        }
    }
    
    class Idle: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reloading.self || stateClass == LoadingMore.self
        }
    }
    
    class LoadingMore: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            viewModel.loadMore()
                .sink { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        stateMachine.enter(Fail.self)
                    case .finished:
                        stateMachine.enter(Idle.self)
                    }
                } receiveValue: { [weak self] response in
                    let newTweetIds = response.value.map { $0.idStr }
                    let idSet = Set(viewModel.userTimelineTweetIDs.value).union(newTweetIds)
                    viewModel.userTimelineTweetIDs.value = Array(idSet)
                }
                .store(in: &viewModel.disposeBag)
        }
    }
    
    class NoMore: UserTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reloading.self
        }
    }
}
