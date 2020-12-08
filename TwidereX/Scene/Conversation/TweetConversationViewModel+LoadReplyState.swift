//
//  TweetConversationViewModel+LoadReplyState.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-4.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit
import CoreDataStack
import TwitterAPI

extension TweetConversationViewModel {
    class LoadReplyState: GKState, NamingState {
        weak var viewModel: TweetConversationViewModel?
        var name: String { "Base" }
        
        init(viewModel: TweetConversationViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, name, (previousState as? NamingState)?.name ?? previousState?.description ?? "nil")
        }
    }
}

extension TweetConversationViewModel.LoadReplyState {
    class Initial: TweetConversationViewModel.LoadReplyState {
        override var name: String { "Initial" }
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Prepare.self || stateClass == NoMore.self
        }
    }
    
    class Prepare: TweetConversationViewModel.LoadReplyState {
        
        override var name: String { "Prepare" }
        
        static let throat = 20
        var previousResolvedNodeCount: Int? = nil
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == Idle.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard case let .root(tweetObjectID) = viewModel.rootItem else { return }
            
            let managedObjectContext = viewModel.context.managedObjectContext
            managedObjectContext.perform { [weak self] in
                guard let self = self else { return }
                guard let tweet = managedObjectContext.object(with: tweetObjectID) as? Tweet else { return }
                
                // collect local reply
                var replyToArray: [Tweet] = []
                var optionalNextReplyTo: Tweet? = tweet.replyTo
                while let next = optionalNextReplyTo {
                    replyToArray.append(next)
                    optionalNextReplyTo = next.replyTo
                }
                
                var replyNodes: [TweetConversationViewModel.ReplyNode] = []
                for replyTo in replyToArray {
                    let node = TweetConversationViewModel.ReplyNode(tweetID: replyTo.id, inReplyToTweetID: replyTo.inReplyToTweetID, status: .success(replyTo.objectID))
                    replyNodes.append(node)
                }
                let last = replyToArray.last ?? tweet
                if let inReplyToTweetID = last.inReplyToTweetID {
                    // have reply to pointer but not resolved
                    // check local database and update relationship
                    do {
                        let request = Tweet.sortedFetchRequest
                        request.fetchLimit = 1
                        request.predicate = Tweet.predicate(idStr: inReplyToTweetID)
                        let inReplyToTweet = try managedObjectContext.fetch(request).first
                        
                        if let inReplyToTweet = inReplyToTweet {
                            // update entity
                            let backgroundManagedObjectContext = viewModel.context.backgroundManagedObjectContext
                            backgroundManagedObjectContext.performChanges {
                                guard let inReplyToTweet = backgroundManagedObjectContext.object(with: inReplyToTweet.objectID) as? Tweet,
                                      let last = backgroundManagedObjectContext.object(with: last.objectID) as? Tweet else {
                                    return
                                }
                                last.update(replyTo: inReplyToTweet)
                            }
                            .sink { result in
                                switch result {
                                case .failure(let error):
                                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: update replyTo for tweet %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, last.id, error.localizedDescription)
                                case .success:
                                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: update replyTo for tweet %s success", ((#file as NSString).lastPathComponent), #line, #function, last.id)
                                }
                            }
                            .store(in: &viewModel.disposeBag)
                            
                            let node = TweetConversationViewModel.ReplyNode(tweetID: inReplyToTweetID, inReplyToTweetID: inReplyToTweet.inReplyToTweetID, status: .success(inReplyToTweet.objectID))
                            replyNodes.append(node)
                            
                            if let nextTweetID = inReplyToTweet.inReplyToTweetID {
                                let nextNode = TweetConversationViewModel.ReplyNode(tweetID: nextTweetID, inReplyToTweetID: nil, status: .notDetermined)
                                replyNodes.append(nextNode)
                            }
                        } else {
                            let node = TweetConversationViewModel.ReplyNode(tweetID: inReplyToTweetID, inReplyToTweetID: nil, status: .notDetermined)
                            replyNodes.append(node)
                        }
                    } catch {
                        assertionFailure(error.localizedDescription)
                    }
                }
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: prepare reply nodes: %s", ((#file as NSString).lastPathComponent), #line, #function, replyNodes.debugDescription)
                viewModel.replyNodes.value = replyNodes
                
                let pendingNodes = replyNodes.filter { node in
                    switch node.status {
                    case .notDetermined, .fail:     return true
                    case .success:                  return false
                    }
                }

                if pendingNodes.isEmpty {
                    stateMachine.enter(NoMore.self)
                } else {
                    if replyNodes.count > Prepare.throat {
                        // stop reply auto lookup
                        stateMachine.enter(Idle.self)
                    } else {
                        let resolvedNodeCount = replyNodes.count - pendingNodes.count
                        if let previousResolvedNodeCount = self.previousResolvedNodeCount {
                            if previousResolvedNodeCount == resolvedNodeCount {
                                stateMachine.enter(Fail.self)
                            } else {
                                stateMachine.enter(Loading.self)
                            }
                        } else {
                            self.previousResolvedNodeCount = resolvedNodeCount
                            stateMachine.enter(Loading.self)
                        }
                    }
                }
            }
        }
    }
    
    class Idle: TweetConversationViewModel.LoadReplyState {
        override var name: String { "Idle" }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: TweetConversationViewModel.LoadReplyState {
        
        override var name: String { "Loading" }

        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Prepare.self || stateClass == Idle.self || stateClass == Fail.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)

            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let authenticationBox = viewModel.context.authenticationService.activeTwitterAuthenticationBox.value else {
                return
            }

            let replyNodes = viewModel.replyNodes.value
            let pendingNodes = replyNodes.filter { node in
                switch node.status {
                case .notDetermined, .fail: return true
                case .success:              return false
                }
            }
            
            guard !pendingNodes.isEmpty else {
                stateMachine.enter(NoMore.self)
                return
            }
            
            let tweetIDs = pendingNodes.map { $0.tweetID }
            viewModel.context.apiService.tweets(tweetIDs: tweetIDs, twitterAuthenticationBox: authenticationBox)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch reply fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        stateMachine.enter(Fail.self)
                    case .finished:
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch reply success: %s", ((#file as NSString).lastPathComponent), #line, #function, tweetIDs.debugDescription)
                        break
                    }
                } receiveValue: { response in
                    stateMachine.enter(Prepare.self)
                }
                .store(in: &viewModel.disposeBag)

        }
    }
    
    class Fail: TweetConversationViewModel.LoadReplyState {
        override var name: String { "Fail" }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
    }
    
    class NoMore: TweetConversationViewModel.LoadReplyState {
        override var name: String { "NoMore" }
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
    }
    
}
