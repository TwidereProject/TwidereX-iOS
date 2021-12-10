//
//  HashtagTimelineViewModel+State.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit

extension HashtagTimelineViewModel {
    class State: GKState {
        weak var viewModel: HashtagTimelineViewModel?
        
        init(viewModel: HashtagTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension HashtagTimelineViewModel.State {
    class Initial: HashtagTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Idle.self || stateClass == Reset.self || stateClass == Loading.self
        }
    }
    
    class Idle: HashtagTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reset.self || stateClass == Loading.self
        }
    }
    
    class Reset: HashtagTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            viewModel?.statusRecordFetchedResultController.reset()
            stateMachine?.enter(Loading.self)
        }
    }
    
    class Loading: HashtagTimelineViewModel.State {
        let logger = Logger(subsystem: "HashtagTimelineViewModel.State", category: "StateMachine")
        
        var nextInput: StatusListFetchViewModel.HashtagInput?
        
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

            let searchText = viewModel.hashtag

            if nextInput == nil {
                nextInput = {
                    switch authenticationContext {
                    case .twitter(let authenticationContext):
                        return StatusListFetchViewModel.HashtagInput.twitter(.init(
                            authenticationContext: authenticationContext,
                            searchText: searchText,
                            onlyMedia: false,
                            nextToken: nil,
                            maxResults: 50
                        ))
                    case .mastodon(let authenticationContext):
                        return StatusListFetchViewModel.HashtagInput.mastodon(.init(
                            authenticationContext: authenticationContext,
                            hashtag: searchText,
                            maxID: nil,
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
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch \(searchText)…")
                    let output = try await StatusListFetchViewModel.hashtagTimeline(
                        context: viewModel.context,
                        input: input
                    )

                    nextInput = output.nextInput

                    if output.hasMore {
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
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
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch failure: \(error.localizedDescription)")
                    debugPrint(error)
                    await enter(state: Fail.self)
                }
            }   // end Task { … }
        }   // end func didEnter(from:)
        
        @MainActor
        func enter(state: HashtagTimelineViewModel.State.Type) {
            stateMachine?.enter(state)
        }
        
    }   // end class Loading: SearchHashtagViewModel.State { … }
    
    
    class Fail: HashtagTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reset.self || stateClass == Loading.self
        }
    }
    
    class NoMore: HashtagTimelineViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reset.self
        }
    }
}
