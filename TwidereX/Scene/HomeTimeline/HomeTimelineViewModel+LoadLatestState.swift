//
//  HomeTimelineViewModel+LoadLatestState.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-9.
//

import os.log
import func QuartzCore.CACurrentMediaTime
import Foundation
import CoreData
import CoreDataStack
import GameplayKit

extension HomeTimelineViewModel {
    class LoadLatestState: GKState {
        weak var viewModel: HomeTimelineViewModel?
        
        init(viewModel: HomeTimelineViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            viewModel?.loadLatestStateMachinePublisher.send(self)
        }
    }
}

extension HomeTimelineViewModel.LoadLatestState {
    class Initial: HomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: HomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Idle.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let twitterAuthenticationBox = viewModel.context.authenticationService.activeTwitterAuthenticationBox.value else {
                stateMachine.enter(Fail.self)
                return
            }
            
            let predicate = viewModel.fetchedResultsController.fetchRequest.predicate
            let parentManagedObjectContext = viewModel.fetchedResultsController.managedObjectContext
            let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            managedObjectContext.parent = parentManagedObjectContext

            managedObjectContext.perform {
                let start = CACurrentMediaTime()
                let tweetIDs: [Tweet.ID]
                let request = TimelineIndex.sortedFetchRequest
                request.returnsObjectsAsFaults = false
                request.predicate = predicate

                do {
                    let timelineIndexes = try managedObjectContext.fetch(request)
                    tweetIDs = timelineIndexes.compactMap { $0.tweet?.id }
                } catch {
                    stateMachine.enter(Fail.self)
                    return
                }
                let end = CACurrentMediaTime()
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: collect tweets id cost: %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - start)
                
                // TODO: only set large count when using Wi-Fi
                viewModel.context.apiService.twitterHomeTimeline(count: 200, twitterAuthenticationBox: twitterAuthenticationBox)
                    .delay(for: .seconds(1), scheduler: DispatchQueue.main)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        switch completion {
                        case .failure(let error):
                            // TODO: handle error
                            viewModel.isFetchingLatestTimeline.value = false
                            os_log("%{public}s[%{public}ld], %{public}s: fetch tweets failed. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        case .finished:
                            // handle isFetchingLatestTimeline in fetch controller delegate
                            break
                        }
                        
                        stateMachine.enter(Idle.self)
                        
                    } receiveValue: { response in
                        // stop refresher if no new tweets
                        let tweets = response.value
                        let newTweets = tweets.filter { !tweetIDs.contains($0.idStr) }
                        os_log("%{public}s[%{public}ld], %{public}s: load %{public}ld new tweets", ((#file as NSString).lastPathComponent), #line, #function, newTweets.count)

                        if newTweets.isEmpty {
                            viewModel.isFetchingLatestTimeline.value = false
                        }
                    }
                    .store(in: &viewModel.disposeBag)
            }
        }
    }
    
    class Fail: HomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == Idle.self
        }
    }
    
    class Idle: HomeTimelineViewModel.LoadLatestState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }

}
