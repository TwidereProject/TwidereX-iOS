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
        
        let id: String
        let logger: Logger
        
        init(viewModel: TimelineViewModel) {
            let last = UUID().uuidString.split(separator: "-").last ?? ""
            let id = String(last)
            self.id = id
            self.viewModel = viewModel
            self.logger = Logger(subsystem: "TimelineViewModel.LoadOldestState", category: "State@\(viewModel.kind.category)#\(id)")
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            let from = previousState.flatMap { String(describing: $0) } ?? "nil"
            let to = String(describing: self)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(from) -> \(to)")
        }
        
        func enter(state: TimelineViewModel.LoadOldestState.Type) {
            stateMachine?.enter(state)
        }
    }
}

extension TimelineViewModel.LoadOldestState {
    
    class Initial: TimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            guard let _ = viewModel else { return false }
            return stateClass == Reloading.self || stateClass == Loading.self
        }
    }
    
    class Reloading: TimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }

            viewModel.statusRecordFetchedResultController.reset()
            stateMachine.enter(Loading.self)
        }
    }
    
    class Loading: TimelineViewModel.LoadOldestState {
        
        var nextInput: StatusFetchViewModel.Timeline.Input?

        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            case is Fail.Type:
                return true
            case is Idle.Type:
                return true
            case is NoMore.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)

            // reset when reloading
            switch previousState {
            case is Reloading:
                nextInput = nil
            default:
                break
            }

            guard let viewModel = viewModel, let _ = stateMachine else { return }
            
            Task {
                let managedObjectContext = viewModel.context.managedObjectContext
                let _anchorRecord: StatusRecord? = await managedObjectContext.perform {
                    switch viewModel.kind {
                    case .home:
                        guard let record = viewModel.feedFetchedResultsController.records.last else { return nil }
                        guard let feed = record.object(in: managedObjectContext) else { return nil }
                        return feed.statusObject?.asRecord
                    case .public, .hashtag, .list, .search, .user:
                        guard let status = viewModel.statusRecordFetchedResultController.records.last else { return nil }
                        return status
                    }
                }

                await fetch(anchor: _anchorRecord)
            }   // end Task
        }   // end func

        private func fetch(anchor record: StatusRecord?) async {
            guard let viewModel = viewModel, let _ = stateMachine else { return }
            
            let authenticationContext = viewModel.authContext.authenticationContext
            
            if nextInput == nil {
                let managedObjectContext = viewModel.context.managedObjectContext
                let fetchContext = StatusFetchViewModel.Timeline.FetchContext(
                    managedObjectContext: managedObjectContext,
                    authenticationContext: authenticationContext,
                    kind: viewModel.kind,
                    position: {
                        // always reload at top when nextInput is nil
                        return .top(anchor: nil)
                    }(),
                    filter: StatusFetchViewModel.Timeline.Filter(rule: .empty)
                )
                do {
                    nextInput = try await StatusFetchViewModel.Timeline.prepare(fetchContext: fetchContext)
                } catch {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(error.localizedDescription)")
                    assertionFailure(error.localizedDescription)
                }
            }

            guard let input = nextInput else {
                enter(state: Fail.self)
                return
            }

            do {
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch…")
                let output = try await StatusFetchViewModel.Timeline.fetch(
                    api: viewModel.context.apiService,
                    input: input
                )
                
                // make sure reentry safe
                guard input == self.nextInput else { return }
                self.nextInput = output.nextInput
                
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): hasMore: \(output.hasMore)")
                if output.hasMore {
                    enter(state: Idle.self)
                } else {
                    enter(state: NoMore.self)
                }
                
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch success")
                switch viewModel.kind {
                case .home:
                    break
                case .hashtag, .public, .list, .search, .user:
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
                }
            } catch {
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch failure: \(error.localizedDescription)")
                enter(state: Fail.self)
            }
        }
        
    }   // end class Loading
    
    class Fail: TimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is Loading.Type:
                return true
            default:
                return false
            }
        }
    }
    
    class Idle: TimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type, is Loading.Type:
                return true
            default:
                return false
            }
        }
    }

    class NoMore: TimelineViewModel.LoadOldestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Reloading.Type:
                return true
            default:
                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            // guard let viewModel = viewModel else { return }
            // guard let diffableDataSource = viewModel.diffableDataSource else {
            //     assertionFailure()
            //     return
            // }
            // var snapshot = diffableDataSource.snapshot()
            // snapshot.deleteItems([.bottomLoader])
            // diffableDataSource.apply(snapshot)
        }
    }
}
