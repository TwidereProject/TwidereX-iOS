//
//  SearchUserViewModel+State.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit
import TwitterAPI

extension SearchUserViewModel {
    class State: GKState {
        weak var viewModel: SearchUserViewModel?
        
        init(viewModel: SearchUserViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            viewModel?.stateMachinePublisher.send(self)
        }
    }
}

extension SearchUserViewModel.State {
    class Initial: SearchUserViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Idle.self || stateClass == Loading.self
        }
    }
    
    class Idle: SearchUserViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: SearchUserViewModel.State {
        var error: Error?
        var previoursSearchText = ""
        var page: Int = 1
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            guard let authentication = viewModel.currentTwitterAuthentication.value,
                  let authorization = try? authentication.authorization(appSecret: .shared) else {
                error = SearchMediaViewModel.SearchMediaError.invalidAuthorization
                stateMachine.enter(Fail.self)
                return
            }
            let searchText = viewModel.searchText.value
            guard !searchText.isEmpty, searchText.count < 512 else {
                error = SearchMediaViewModel.SearchMediaError.invalidSearchText
                stateMachine.enter(Fail.self)
                return
            }
            if searchText != previoursSearchText {
                page = 1
                previoursSearchText = searchText
                viewModel.searchTwitterUserIDs.value = []
                viewModel.items.value = []
            }
            
            let count = 20
            viewModel.context.apiService.userSearch(
                searchText: searchText,
                page: page,
                count: count,
                authorization: authorization,
                requestTwitterUserID: authentication.userID
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
                let entities = response.value
                self.page += 1
                os_log("%{public}s[%{public}ld], %{public}s: search %s success. results count %ld", ((#file as NSString).lastPathComponent), #line, #function, searchText, entities.count)
                
                guard entities.count > 0 else {
                    stateMachine.enter(NoMore.self)
                    return
                }
                
                let newTwitterUsers = entities
                let oldTwitterUserIDs = viewModel.searchTwitterUserIDs.value
                
                var twitterUserIDs: [Twitter.Entity.Tweet.ID] = []
                for twitterUserID in oldTwitterUserIDs {
                    guard !twitterUserIDs.contains(twitterUserID) else { continue }
                    twitterUserIDs.append(twitterUserID)
                }
                
                for twitterUser in newTwitterUsers {
                    guard !twitterUserIDs.contains(twitterUser.idStr) else { continue }
                    twitterUserIDs.append(twitterUser.idStr)
                }
                
                viewModel.searchTwitterUserIDs.value = twitterUserIDs
                
                if entities.count < count {
                    stateMachine.enter(NoMore.self)
                } else {
                    stateMachine.enter(Idle.self)
                }
            }
            .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: SearchUserViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class NoMore: SearchUserViewModel.State {
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
