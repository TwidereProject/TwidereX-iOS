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
                await fetch(feed: feed)
            }
            
            
//            guard let activeTwitterAuthenticationBox = viewModel.context.authenticationService.activeTwitterAuthenticationBox.value else {
//                assertionFailure()
//                stateMachine.enter(Fail.self)
//                return
//            }
//
//            guard let last = viewModel.fetchedResultsController.fetchedObjects?.last,
//                  let tweet = last.tweet else {
//                stateMachine.enter(Idle.self)
//                return
//            }
//
//            // TODO: only set large count when using Wi-Fi
//            let maxID = tweet.id
//            viewModel.context.apiService.twitterHomeTimeline(count: 200, maxID: maxID, twitterAuthenticationBox: activeTwitterAuthenticationBox)
//                .delay(for: .seconds(1), scheduler: DispatchQueue.main)
//                .receive(on: DispatchQueue.main)
//                .sink { completion in
//                    switch completion {
//                    case .failure(let error):
//                        // TODO: handle error
//                        os_log("%{public}s[%{public}ld], %{public}s: fetch tweets failed. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//                    case .finished:
//                        // handle isFetchingLatestTimeline in fetch controller delegate
//                        break
//                    }
//                } receiveValue: { response in
//                    let tweets = response.value
//                    // enter no more state when no new tweets
//                    if tweets.isEmpty || (tweets.count == 1 && tweets[0].idStr == maxID) {
//                        stateMachine.enter(NoMore.self)
//                    } else {
//                        stateMachine.enter(Idle.self)
//                    }
//                }
//                .store(in: &viewModel.disposeBag)
        }
        
        enum FetchContext {
            case twitter(TwitterFetchContext)
            case mastodon(MastodonFetchContext)
        }
        
        struct TwitterFetchContext {
            let maxID: TwitterStatus.ID
        }
        
        struct MastodonFetchContext {
            let maxID: MastodonStatus.ID
        }
        
        func fetch(feed record: ManagedObjectRecord<Feed>) async {
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }

            let managedObjectContext = viewModel.context.managedObjectContext
            let _fetchContext: FetchContext? = await managedObjectContext.perform {
                guard let feed = record.object(in: managedObjectContext) else { return nil }
                switch feed.content {
                case .twitter(let status):
                    let fetchContext = TwitterFetchContext(maxID: status.id)
                    return .twitter(fetchContext)
                case .mastodon(let status):
                    let fetchContext = MastodonFetchContext(maxID: status.id)
                    return .mastodon(fetchContext)
                case .none:
                    assertionFailure()
                    return nil
                }
            }
            
            guard let fetchContext = _fetchContext else {
                stateMachine.enter(Fail.self)
                return
            }

            do {
                switch fetchContext {
                case .twitter(let fetchContext):
                    try await fetch(fetchContext: fetchContext)
                case .mastodon(let mastodonFetchContext):
                    break
                }
            } catch {
                stateMachine.enter(Fail.self)
                return
            }
        }
        
        func fetch(fetchContext: TwitterFetchContext) async throws {
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let authenticationContext = viewModel.context.authenticationService.activeAuthenticationContext.value?.twitterAuthenticationContext else { return }
            let response = try await viewModel.context.apiService.twitterHomeTimeline(
                maxID: fetchContext.maxID,
                authenticationContext: authenticationContext
            )
            let notHasMore = response.value.isEmpty || (response.value.count == 1 && response.value[0].idStr == fetchContext.maxID)
            if notHasMore {
                stateMachine.enter(NoMore.self)
            } else {
                stateMachine.enter(Idle.self)
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
