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
        
        var nextInput: StatusListFetchViewModel.SearchInput?
        
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
                        return StatusListFetchViewModel.SearchInput.twitter(.init(
                            authenticationContext: authenticationContext,
                            searchText: searchText,
                            onlyMedia: false,
                            nextToken: nil,
                            maxResults: 50
                        ))
                    case .mastodon(let authenticationContext):
                        let offset = viewModel.statusRecordFetchedResultController.mastodonStatusFetchedResultController.statusIDs.value.count
                        return StatusListFetchViewModel.SearchInput.mastodon(.init(
                            authenticationContext: authenticationContext,
                            searchText: searchText,
                            offset: offset,
                            limit: 50
                        ))
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
                    let output = try await StatusListFetchViewModel.searchTimeline(
                        context: viewModel.context,
                        input: input
                    )
                    
                    // check task is valid
                    guard viewModel.searchText == searchText else { return }
                    
                    nextInput = output.nextInput
                    if output.hasMore {
                        stateMachine.enter(Idle.self)
                    } else {
                        stateMachine.enter(NoMore.self)
                    }
                    
                    switch output.result {
                    case .twitter(let statuses):
                        let statusIDs = statuses.map { $0.idStr }
                        viewModel.statusRecordFetchedResultController.twitterStatusFetchedResultController.append(statusIDs: statusIDs)
                    case .twitterV2(let statuses):
                        let statusIDs = statuses.map { $0.id }
                        viewModel.statusRecordFetchedResultController.twitterStatusFetchedResultController.append(statusIDs: statusIDs)
                    case .mastodon(let statuses):
                        let statusIDs = statuses.map { $0.id }
                        viewModel.statusRecordFetchedResultController.mastodonStatusFetchedResultController.append(statusIDs: statusIDs)
                    }
                } catch let error {
                    // check task is valid
                    guard viewModel.searchText == searchText else { return }
                    
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch failure: \(error.localizedDescription)")
                    debugPrint(error)
                    stateMachine.enter(Fail.self)
                }
            }   // end currentTask = Task { … }
        }   // end func didEnter(from:)
        
    }   // end class Loading: SearchTimelineViewModel.State { … }

    
    class Fail: SearchTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reset.self || stateClass == Loading.self
        }
    }
    
    class NoMore: SearchTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reset.self
        }
    }
}