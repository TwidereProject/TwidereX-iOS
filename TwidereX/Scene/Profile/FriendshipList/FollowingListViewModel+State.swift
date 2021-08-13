//
//  FriendshipListViewModel+State.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit
import TwitterSDK

extension FriendshipListViewModel {
    class State: GKState {
        weak var viewModel: FriendshipListViewModel?
        
        init(viewModel: FriendshipListViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension FriendshipListViewModel.State {
    class Initial: FriendshipListViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Idle.self || stateClass == Loading.self
        }
    }
    
    class Idle: FriendshipListViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: FriendshipListViewModel.State {
        var nextToken: String?
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self || stateClass == NoMore.self || stateClass == PermissionDenied.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let twitterAuthenticationBox = viewModel.context.authenticationService.activeTwitterAuthenticationBox.value else {
                stateMachine.enter(Fail.self)
                return
            }
            
            // trigger data source update
            if previousState is Initial {
                viewModel.orderedTwitterUserFetchedResultsController.userIDs.value = []
            }
            
            viewModel.context.apiService.friendshipList(
                kind: viewModel.friendshipLookupKind,
                userID: viewModel.userID,
                maxResults: nextToken == nil ? 200 : 1000,      // small batch at the first time fetching
                paginationToken: nextToken,
                twitterAuthenticationBox: twitterAuthenticationBox
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: fetch following listfail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    if PermissionDenied.canEnter(for: error) {
                        stateMachine.enter(PermissionDenied.self)
                    } else {
                        stateMachine.enter(Fail.self)
                    }
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                var userIDs = viewModel.orderedTwitterUserFetchedResultsController.userIDs.value
                let users = response.value.data ?? []
                for user in users {
                    guard !userIDs.contains(user.id) else { continue }
                    userIDs.append(user.id)
                }
                
                if let nextToken = response.value.meta.nextToken {
                    self.nextToken = nextToken
                    stateMachine.enter(Idle.self)
                } else {
                    self.nextToken = nil
                    stateMachine.enter(NoMore.self)
                }
                
                viewModel.orderedTwitterUserFetchedResultsController.userIDs.value = userIDs
            }
            .store(in: &viewModel.disposeBag)
        }
    }
    
    class Fail: FriendshipListViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class PermissionDenied: FriendshipListViewModel.State {
        static func canEnter(for error: Error) -> Bool {
            if let responseError = error as? Twitter.API.Error.ResponseError,
               let twitterAPIError = responseError.twitterAPIError,
               case .notAuthorizedToSeeThisStatus = twitterAPIError {
                return true
            }
            
            return false
        }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel else { return }
            
            // trigger items update
            viewModel.orderedTwitterUserFetchedResultsController.userIDs.value = []
        }
    }
    
    class NoMore: FriendshipListViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
        }
    }
    
}
