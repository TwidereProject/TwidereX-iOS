//
//  TweetConversationViewModel+LoadConversationState.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-15.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import GameplayKit
import CoreDataStack
import TwitterAPI

extension TweetConversationViewModel {
    class LoadConversationState: GKState, NamingState {
        weak var viewModel: TweetConversationViewModel?
        var name: String { "Base" }
                
        init(viewModel: TweetConversationViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, name, (previousState as? NamingState)?.name ?? previousState?.description ?? "nil")
            // guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
        }
    }
}

extension TweetConversationViewModel.LoadConversationState {
    class Initial: TweetConversationViewModel.LoadConversationState {
        override var name: String { "Initial" }
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Prepare.self
        }
    }
    
    class Prepare: TweetConversationViewModel.LoadConversationState {
        override var name: String { "Prepare" }
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Idle.self || stateClass == PrepareFail.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard case let .root(tweetObjectID)  = viewModel.rootItem.value else {
                assertionFailure()
                stateMachine.enter(PrepareFail.self)
                return
            }

            var _tweetID: Twitter.Entity.V2.Tweet.ID?
            var _authorID: Twitter.Entity.V2.User.ID?
            var _conversationID: Twitter.Entity.V2.Tweet.ConversationID?
            var _createdAt: Date?
            viewModel.context.managedObjectContext.perform {
                let tweet = viewModel.context.managedObjectContext.object(with: tweetObjectID) as! Tweet
                _tweetID = (tweet.retweet ?? tweet).id
                _authorID = (tweet.retweet ?? tweet).author.id
                _conversationID = (tweet.retweet ?? tweet).conversationID
                _createdAt = (tweet.retweet ?? tweet).createdAt
             
                DispatchQueue.main.async {
                    guard let tweetID = _tweetID, let authorID = _authorID, let createdAt = _createdAt else {
                        assertionFailure()
                        stateMachine.enter(PrepareFail.self)
                        return
                    }
                    
                    if let conversationID = _conversationID {
                        viewModel.conversationMeta.value = .init(
                            tweetID: tweetID,
                            authorID: authorID,
                            conversationID: conversationID,
                            createdAt: createdAt
                        )
                        stateMachine.enter(Idle.self)
                        stateMachine.enter(Loading.self)
                    } else {
                        guard let activeTwitterAuthenticationBox = viewModel.context.authenticationService.activeTwitterAuthenticationBox.value else
                        {
                            assertionFailure()
                            stateMachine.enter(PrepareFail.self)
                            return
                        }
                        viewModel.context.apiService.tweets(tweetIDs: [tweetID], twitterAuthenticationBox: activeTwitterAuthenticationBox)
                            .receive(on: DispatchQueue.main)
                            .sink { completion in
                                switch completion {
                                case .failure(let error):
                                    os_log("%{public}s[%{public}ld], %{public}s: fetch tweet conversationID fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                                    debugPrint(error)
                                    stateMachine.enter(PrepareFail.self)
                                case .finished:
                                    break
                                }
                            } receiveValue: { response in
                                let content = response.value
                                guard let entity = content.data?.first,
                                      let conversationID = entity.conversationID else
                                {
                                    stateMachine.enter(PrepareFail.self)
                                    return
                                }
                                os_log("%{public}s[%{public}ld], %{public}s: fetch tweet %s conversationID: %s", ((#file as NSString).lastPathComponent), #line, #function, tweetID, entity.conversationID ?? "<nil>")
                                
                                viewModel.conversationMeta.value = .init(
                                    tweetID: tweetID,
                                    authorID: authorID,
                                    conversationID: conversationID,
                                    createdAt: createdAt
                                )
                                stateMachine.enter(Idle.self)
                                stateMachine.enter(Loading.self)
                            }
                            .store(in: &viewModel.disposeBag)
                    }
                }   // end DispatchQueue.main.async
            }   // end viewModel.context.managedObjectContext.perform
        }
    }
    
    class PrepareFail: TweetConversationViewModel.LoadConversationState {
        override var name: String { "PrepareFail" }
        var prepareFailCount = 0

        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Prepare.self || stateClass == Fail.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            // retry 3 times
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self = self else { return }
                guard let stateMachine = self.stateMachine else { return }

                guard self.prepareFailCount < 3 else {
                    stateMachine.enter(Fail.self)
                    return
                }
                self.prepareFailCount += 1
                stateMachine.enter(Prepare.self)
            }
        }
    }
    
    class Idle: TweetConversationViewModel.LoadConversationState {
        override var name: String { "Idle" }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: TweetConversationViewModel.LoadConversationState {
        
        var nextToken: String?
        override var name: String { "Loading" }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Idle.self || stateClass == Fail.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let conversationMeta = viewModel.conversationMeta.value else {
                assertionFailure()
                stateMachine.enter(Fail.self)
                return
            }
            
            guard let activeTwitterAuthenticationBox = viewModel.context.authenticationService.activeTwitterAuthenticationBox.value else
            {
                assertionFailure()
                stateMachine.enter(Fail.self)
                return
            }
            
            let sevenDaysAgo = Date(timeInterval: -((7 * 24 * 60 * 60) - (5 * 60)), since: Date())
            var sinceID: Twitter.Entity.V2.Tweet.ID?
            var startTime: Date?
            if conversationMeta.createdAt < sevenDaysAgo {
                startTime = sevenDaysAgo
            } else {
                sinceID = conversationMeta.tweetID
            }
            
            viewModel.context.apiService.tweetsRecentSearch(
                conversationID: conversationMeta.conversationID,
                authorID: conversationMeta.authorID,
                sinceID: sinceID,
                startTime: startTime,
                nextToken: self.nextToken,
                twitterAuthenticationBox: activeTwitterAuthenticationBox
            )
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: fetch conversation %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, conversationMeta.conversationID, error.localizedDescription)
                    debugPrint(error)
                    stateMachine.enter(Idle.self)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                let content = response.value
                os_log("%{public}s[%{public}ld], %{public}s: fetch conversation %s success. results count %ld", ((#file as NSString).lastPathComponent), #line, #function, conversationMeta.conversationID, content.meta.resultCount)

                guard content.meta.resultCount > 0 else {
                    stateMachine.enter(NoMore.self)
                    return
                }
                
                let leafs = TweetConversationViewModel.ConversationNode.leafs(for: conversationMeta.tweetID, from: content)
                let nodes = viewModel.conversationNodes.value
                viewModel.conversationNodes.value = nodes + leafs
                
                guard let nextToken = content.meta.nextToken else {
                    stateMachine.enter(NoMore.self)
                    return
                }
                self.nextToken = nextToken
                stateMachine.enter(Idle.self)

            }
            .store(in: &viewModel.disposeBag)

        }
    }
    
    class Fail: TweetConversationViewModel.LoadConversationState {
        override var name: String { "Fail" }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel else { return }
            
            // trigger diffable data source update
            viewModel.conversationItems.value = viewModel.conversationItems.value
        }
    }
    
    class NoMore: TweetConversationViewModel.LoadConversationState {
        override var name: String { "NoMore" }
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel else { return }
            
            // trigger diffable data source update
            viewModel.conversationItems.value = viewModel.conversationItems.value
        }
    }
    
}
