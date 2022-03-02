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
import TwitterSDK

extension SearchUserViewModel {
    class State: GKState {
        weak var viewModel: SearchUserViewModel?
        
        init(viewModel: SearchUserViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension SearchUserViewModel.State {
    class Initial: SearchUserViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Idle.self || stateClass == Reset.self || stateClass == Loading.self
        }
    }
    
    class Idle: SearchUserViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reset.self || stateClass == Loading.self
        }
    }
    
    class Reset: SearchUserViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            viewModel?.userRecordFetchedResultController.reset()
            stateMachine?.enter(Loading.self)
        }
    }
    
    class Loading: SearchUserViewModel.State {
        let logger = Logger(subsystem: "SearchUserViewModel.State", category: "StateMachine")
        
        var nextInput: UserFetchViewModel.Search.Input?
        
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
            }
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let authenticationContext = viewModel.context.authenticationService.activeAuthenticationContext
            else {
                stateMachine.enter(Fail.self)
                return
            }
            
            let searchText = viewModel.searchText
            if nextInput == nil {
                nextInput = {
                    switch authenticationContext {
                    case .twitter(let authenticationContext):
                        return UserFetchViewModel.Search.Input.twitter(.init(
                            authenticationContext: authenticationContext,
                            searchText: searchText,
                            page: 1,    // count from 1
                            count: 50
                        ))
                    case .mastodon(let authenticationContext):
                        return UserFetchViewModel.Search.Input.mastodon(.init(
                            authenticationContext: authenticationContext,
                            searchText: searchText,
                            offset: 0,
                            count: 50)
                        )
                    }
                }()
            }
            
            guard let input = nextInput else {
                stateMachine.enter(Fail.self)
                return
            }
            
            Task {
                do {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch…")
                    
                    let output = try await UserFetchViewModel.Search.timeline(
                        context: viewModel.context,
                        input: input
                    )
                    
                    // check task is valid
                    guard viewModel.searchText == searchText else { return }
                    
                    nextInput = output.nextInput
                    if output.hasMore {
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }
                    
                    switch output.result {
                    case .twitter(let users):
                        let userIDs = users.map { $0.idStr }
                        viewModel.userRecordFetchedResultController.twitterUserFetchedResultsController.append(userIDs: userIDs)
                    case .twitterV2(let users):
                        let userIDs = users.map { $0.id }
                        viewModel.userRecordFetchedResultController.twitterUserFetchedResultsController.append(userIDs: userIDs)
                    case .mastodon(let users):
                        let userIDs = users.map { $0.id }
                        viewModel.userRecordFetchedResultController.mastodonUserFetchedResultController.append(userIDs: userIDs)
                    }
                } catch {
                    // check task is valid
                    guard viewModel.searchText == searchText else { return }
                    
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch failure: \(error.localizedDescription)")
                    await enter(state: Fail.self)
                }
            }   // end currentTask = Task { … }
        }
        
        @MainActor
        func enter(state: SearchUserViewModel.State.Type) {
            stateMachine?.enter(state)
        }
    }
    
    class Fail: SearchUserViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reset.self || stateClass == Loading.self
        }
    }
    
    class NoMore: SearchUserViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reset.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
//            guard let viewModel = viewModel else { return }
//            guard let diffableDataSource = viewModel.diffableDataSource else { return }
//            var snapshot = diffableDataSource.snapshot()
//            if snapshot.itemIdentifiers.contains(.bottomLoader) {
//                snapshot.deleteItems([.bottomLoader])
//                diffableDataSource.apply(snapshot, animatingDifferences: false)
//            }
        }
    }
    
}
