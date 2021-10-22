//
//  HomeTimelineViewModel+LoadOldestState.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-9.
//

import os.log
import Foundation
import GameplayKit
import CoreDataStack

extension HomeTimelineViewModel {
    class LoadOldestState: GKState {
        weak var viewModel: HomeTimelineViewModel?
        
        init(viewModel: HomeTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension HomeTimelineViewModel.LoadOldestState {
    class Initial: HomeTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            guard !viewModel.fetchedResultsController.records.value.isEmpty else { return false }
            return stateClass == Loading.self
        }
    }
    
    class Loading: HomeTimelineViewModel.LoadOldestState {
        let logger = Logger(subsystem: "HomeTimelineViewModel.LoadOldestState", category: "StateMachine")
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            guard let feed = viewModel.fetchedResultsController.records.value.last else {
                stateMachine.enter(Fail.self)
                return
            }
            
            Task {
                await fetch(anchor: feed)
            }
        }

        private func fetch(anchor record: ManagedObjectRecord<Feed>) async {
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            guard let authenticationContext = viewModel.context.authenticationService.activeAuthenticationContext.value else {
                stateMachine.enter(Fail.self)
                return
            }
            
            // generate input from timeline last feed entry
            let managedObjectContext = viewModel.context.managedObjectContext
            let _input: StatusListFetchViewModel.Input? = await managedObjectContext.perform {
                guard let feed = record.object(in: managedObjectContext) else { return nil }
                switch (feed.content, authenticationContext) {
                case (.twitter(let status), .twitter(let authenticationContext)):
                    return StatusListFetchViewModel.Input(
                        fetchContext: .twitter(.init(
                            authenticationContext: authenticationContext,
                            searchText: nil,
                            maxID: status.id,
                            nextToken: nil,
                            count: 100,
                            excludeReplies: false,
                            userIdentifier: nil
                        ))
                    )
                case (.mastodon(let status), .mastodon(let authenticationContext)):
                    return StatusListFetchViewModel.Input(
                        fetchContext: .mastodon(.init(
                            authenticationContext: authenticationContext,
                            maxID: status.id,
                            count: 100,
                            excludeReplies: false,
                            excludeReblogs: false,
                            onlyMedia: false,
                            userIdentifier: nil
                        ))
                    )
                default:
                    return nil
                }
            }

            guard let input = _input else {
                stateMachine.enter(Fail.self)
                return
            }

            do {
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch…")
                let output = try await StatusListFetchViewModel.homeTimeline(context: viewModel.context, input: input)
                if output.hasMore {
                    stateMachine.enter(Idle.self)
                } else {
                    stateMachine.enter(NoMore.self)
                }
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch success")
            } catch {
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch failure: \(error.localizedDescription)")
                stateMachine.enter(Fail.self)
            }
        }
    }
    
    class Fail: HomeTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == Idle.self
        }
    }
    
    class Idle: HomeTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }

    class NoMore: HomeTimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // reset state if needs
            return stateClass == Idle.self
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
