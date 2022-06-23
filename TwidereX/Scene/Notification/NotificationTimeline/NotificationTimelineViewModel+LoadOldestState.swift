//
//  NotificationTimelineViewModel+LoadOldestState.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit
import CoreDataStack

extension NotificationTimelineViewModel {
    class LoadOldestState: GKState {
        weak var viewModel: NotificationTimelineViewModel?
        
        init(viewModel: NotificationTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension NotificationTimelineViewModel.LoadOldestState {
    class Initial: NotificationTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            guard !viewModel.fetchedResultsController.records.isEmpty else { return false }
            return stateClass == Loading.self
        }
    }
    
    class Loading: NotificationTimelineViewModel.LoadOldestState {
        let logger = Logger(subsystem: "NotificationTimelineViewModel.LoadOldestState", category: "StateMachine")
                
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self
                || stateClass == Idle.self
                || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let authenticationContext = viewModel.context.authenticationService.activeAuthenticationContext
            else {
                stateMachine.enter(Fail.self)
                return
            }
            
            guard let lsatFeedRecord = viewModel.fetchedResultsController.records.last else {
                stateMachine.enter(Fail.self)
                return
            }
            
            Task {
                // generate input from timeline last feed entry
                let managedObjectContext = viewModel.context.managedObjectContext
                let _input: NotificationFetchViewModel.Input? = await managedObjectContext.perform {
                    guard let feed = lsatFeedRecord.object(in: managedObjectContext) else { return nil }
                    switch (feed.content, authenticationContext) {
                    case (.twitter(let status), .twitter(let authenticationContext)):
                        return NotificationFetchViewModel.Input.twitter(.init(
                            authenticationContext: authenticationContext,
                            maxID: status.id,
                            count: 20
                        ))
                        
                    case (.mastodonNotification(let notification), .mastodon(let authenticationContext)):
                        return NotificationFetchViewModel.Input.mastodon(.init(
                            authenticationContext: authenticationContext,
                            maxID: notification.id,
                            excludeTypes: viewModel.scope._excludeTypes,
                            limit: 20
                        ))
                    default:
                        return nil
                    }
                }

                guard let input = _input else {
                    await enter(state: Fail.self)
                    return
                }

                do {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch…")
                    let output = try await NotificationFetchViewModel.timeline(api: viewModel.context.apiService, input: input)
                    if output.hasMore {
                        await enter(state: Idle.self)
                    } else {
                        await enter(state: NoMore.self)
                    }
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch success")
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch failure: \(error.localizedDescription)")
                    await enter(state: Fail.self)
                }
            }
        }
        
        @MainActor
        func enter(state: NotificationTimelineViewModel.LoadOldestState.Type) {
            stateMachine?.enter(state)
        }

    }
    
    class Fail: NotificationTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == Idle.self
        }
    }
    
    class Idle: NotificationTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }

    class NoMore: NotificationTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
        
        override func didEnter(from previousState: GKState?) {
            guard let viewModel = viewModel else { return }
            guard let diffableDataSource = viewModel.diffableDataSource else {
                assertionFailure()
                return
            }
            var snapshot = diffableDataSource.snapshot()
            snapshot.deleteItems([.bottomLoader])
            diffableDataSource.apply(snapshot)
        }
    }
}
