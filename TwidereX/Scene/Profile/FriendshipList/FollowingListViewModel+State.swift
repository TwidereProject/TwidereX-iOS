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
        let logger = Logger(subsystem: "FriendshipListViewModel.State", category: "StateMachine")
        
        var nextInput: UserListFetchViewModel.FriendshipListInput?
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self
                || stateClass == Idle.self
                || stateClass == NoMore.self
                || stateClass == PermissionDenied.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let authenticationContext = viewModel.context.authenticationService.activeAuthenticationContext.value
            else {
                stateMachine.enter(Fail.self)
                return
            }

            if nextInput == nil {
                nextInput = {
                    switch (viewModel.userIdentifier, authenticationContext) {
                    case (.twitter(let identifier), .twitter(let authenticationContext)):
                        return UserListFetchViewModel.FriendshipListInput.twitter(.init(
                            authenticationContext: authenticationContext,
                            kind: viewModel.kind,
                            userID: identifier.id,
                            paginationToken: nil,
                            maxResults: nil
                        ))
                    case (.mastodon(let identifier), .mastodon(let authenticationContext)):
                        return UserListFetchViewModel.FriendshipListInput.mastodon(.init(
                            authenticationContext: authenticationContext,
                            kind: viewModel.kind,
                            userID: identifier.id,
                            maxID: nil,
                            limit: nil
                        ))
                    default:
                        assertionFailure()
                        return nil
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
                    
                    let output = try await UserListFetchViewModel.friendshipList(
                        context: viewModel.context,
                        input: input
                    )
                    
                    nextInput = output.nextInput
                    if output.hasMore {
                        stateMachine.enter(Idle.self)
                    } else {
                        stateMachine.enter(NoMore.self)
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
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch failure: \(error.localizedDescription)")
                    if PermissionDenied.canEnter(for: error) {
                        stateMachine.enter(PermissionDenied.self)
                    } else {
                        stateMachine.enter(Fail.self)
                    }
                }
            }   // end Task { … }
        }   // end func didEnter
    }   // end class Loading
    
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
            viewModel.userRecordFetchedResultController.reset()
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
