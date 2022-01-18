//
//  TimelineViewModel+LoadOldestState.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-9.
//

import os.log
import Foundation
import GameplayKit
import CoreDataStack
import TwidereCore

extension TimelineViewModel {
    class LoadOldestState: GKState {
        weak var viewModel: TimelineViewModel?
        
        init(viewModel: TimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension TimelineViewModel.LoadOldestState {
    
    class Initial: TimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let viewModel = viewModel else { return false }
            guard let snapshot = viewModel.diffableDataSource?.snapshot() else { return false }
            let didLoadStatus = snapshot.itemIdentifiers.contains(where: { item in
                switch item {
                case .feed:     return true
                case .status:   return true
                default:        return false
                }
            })
            guard didLoadStatus else { return false }
            return stateClass == Loading.self
        }
    }
    
    class Loading: TimelineViewModel.LoadOldestState {
        let logger = Logger(subsystem: "TimelineViewModel.LoadOldestState", category: "StateMachine")
        
        var nextInput: StatusListFetchViewModel.Input?

        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            Task {
                let managedObjectContext = viewModel.context.managedObjectContext
                let _anchorRecord: StatusRecord? = await managedObjectContext.perform {
                    switch viewModel.kind {
                    case .home:
                        guard let feed = viewModel.fetchedResultsController.records.value.last else { return nil }
                        guard let content = feed.object(in: managedObjectContext)?.content else { return nil }
                        switch content {
                        case .twitter(let status):
                            return .twitter(record: .init(objectID: status.objectID))
                        case .mastodon(let status):
                            return .mastodon(record: .init(objectID: status.objectID))
                        default:
                            return nil
                        }
                    case .federated:
                        guard let status = viewModel.statusRecordFetchedResultController.records.value.last else { return nil }
                        return status
                    }
                }
            
                guard let anchorRecord = _anchorRecord else {
                    await enter(state: Fail.self)
                    return
                }

                await fetch(anchor: anchorRecord)
            }
        }

        private func fetch(anchor record: StatusRecord) async {
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            
            guard let authenticationContext = viewModel.context.authenticationService.activeAuthenticationContext.value else {
                await enter(state: Fail.self)
                return
            }
            
            if nextInput == nil {
                let managedObjectContext = viewModel.context.managedObjectContext
                nextInput = await managedObjectContext.perform {
                    guard let status = record.object(in: managedObjectContext) else { return nil }
                    switch (status, authenticationContext) {
                    case (.twitter(let status), .twitter(let authenticationContext)):
                        return StatusListFetchViewModel.Input(
                            fetchContext: .twitter(.init(
                                authenticationContext: authenticationContext,
                                searchText: nil,
                                maxID: status.id,
                                nextToken: nil,
                                count: 100,
                                excludeReplies: false,
                                onlyMedia: false,
                                userIdentifier: nil
                            ))
                        )
                    case (.mastodon(let status), .mastodon(let authenticationContext)):
                        return StatusListFetchViewModel.Input(
                            fetchContext: .mastodon(.init(
                                authenticationContext: authenticationContext,
                                searchText: nil,
                                offset: nil,
                                maxID: status.id,
                                count: 100,
                                excludeReplies: false,
                                excludeReblogs: false,
                                onlyMedia: false,
                                userIdentifier: nil,
                                local: {
                                    switch viewModel.kind {
                                    case .federated(let local):     return local
                                    default:                        return false
                                    }
                                }()
                            ))
                        )
                    default:
                        return nil
                    }
                }
            }

            guard let input = nextInput else {
                await enter(state: Fail.self)
                return
            }

            do {
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch…")
                let output: StatusListFetchViewModel.Output = try await {
                    switch viewModel.kind {
                    case .home:
                        return try await StatusListFetchViewModel.homeTimeline(context: viewModel.context, input: input)
                    case .federated:
                        return try await StatusListFetchViewModel.publicTimeline(context: viewModel.context, input: input)
                    }
                }()
                
                self.nextInput = output.nextInput
                
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): hasMore: \(output.hasMore)")
                if output.hasMore {
                    await enter(state: Idle.self)
                } else {
                    await enter(state: NoMore.self)
                }
                
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch success")
                switch viewModel.kind {
                case .home:
                    break
                case .federated:
                    switch output.result {
                    case .mastodon(let statuses):
                        let statusIDs = statuses.map { $0.id }
                        viewModel.statusRecordFetchedResultController.mastodonStatusFetchedResultController.append(statusIDs: statusIDs)
                    default:
                        assertionFailure()
                    }
                }
            } catch {
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch failure: \(error.localizedDescription)")
                await enter(state: Fail.self)
            }
        }
        
        @MainActor
        func enter(state: TimelineViewModel.LoadOldestState.Type) {
            stateMachine?.enter(state)
        }
        
    }   // end class Loading
    
    class Fail: TimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == Idle.self
        }
    }
    
    class Idle: TimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }

    class NoMore: TimelineViewModel.LoadOldestState {
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
