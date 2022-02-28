//
//  SearchHashtagViewModel+State.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-5.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit

extension SearchHashtagViewModel {
    class State: GKState {
        weak var viewModel: SearchHashtagViewModel?
        
        init(viewModel: SearchHashtagViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension SearchHashtagViewModel.State {
    class Initial: SearchHashtagViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Idle.self || stateClass == Reset.self || stateClass == Loading.self
        }
    }
    
    class Idle: SearchHashtagViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reset.self || stateClass == Loading.self
        }
    }
    
    class Reset: SearchHashtagViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            viewModel?.items = []
            stateMachine?.enter(Loading.self)
        }
    }
    
    class Loading: SearchHashtagViewModel.State {
        let logger = Logger(subsystem: "SearchHashtagViewModel.State", category: "StateMachine")
        
        var nextInput: HashtagListFetchViewModel.SearchInput?
        
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
                        assertionFailure()
                        return nil
                    case .mastodon(let authenticationContext):
                        return HashtagListFetchViewModel.SearchInput.mastodon(.init(
                            authenticationContext: authenticationContext,
                            searchText: searchText,
                            offset: 0,
                            count: 50
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
                    let output = try await HashtagListFetchViewModel.search(
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
                    case .mastodon(let hashtags):
                        var items = viewModel.items
                        var itemHashValues = Set(items.map { $0.hashValue })
                        for hashtag in hashtags {
                            let item = HashtagItem.hashtag(.mastodon(data: hashtag))
                            let itemHashValue = item.hashValue
                            guard !itemHashValues.contains(itemHashValue) else { continue }
                            items.append(item)
                            itemHashValues.insert(itemHashValue)
                        }
                        viewModel.items = items
                    }
                } catch let error {
                    // check task is valid
                    guard viewModel.searchText == searchText else { return }
                    
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch failure: \(error.localizedDescription)")
                    debugPrint(error)
                    await enter(state: Fail.self)
                }
            }   // end currentTask = Task { … }
        }   // end func didEnter(from:)
        
        @MainActor
        func enter(state: SearchHashtagViewModel.State.Type) {
            stateMachine?.enter(state)
        }
        
    }   // end class Loading: SearchHashtagViewModel.State { … }
    
    
    class Fail: SearchHashtagViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reset.self || stateClass == Loading.self
        }
    }
    
    class NoMore: SearchHashtagViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Reset.self
        }
    }
}
