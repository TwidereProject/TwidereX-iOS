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
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard case let .root(tweetObjectID) = viewModel.rootItem else { return }
            
            let managedObjectContext = viewModel.context.managedObjectContext
            managedObjectContext.perform {
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
                    let node = TweetConversationViewModel.ReplyNode(tweetID: inReplyToTweetID, inReplyToTweetID: nil, status: .notDetermined)
                    replyNodes.append(node)
                }
                viewModel.replyNodes.value = replyNodes
                stateMachine.enter(Loading.self)
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
            return stateClass == Idle.self || stateClass == Fail.self || stateClass == NoMore.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)

            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            // print(viewModel.replyNodes.value.debugDescription)
            let replyNodes = viewModel.replyNodes.value
            let last = replyNodes.last(where: { node in
                switch node.status {
                case .notDetermined, .fail: return true
                case .success:              return false
                }
            })
        }
    }
    
    class Fail: TweetConversationViewModel.LoadReplyState {
        override var name: String { "Fail" }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class NoMore: TweetConversationViewModel.LoadReplyState {
        override var name: String { "NoMore" }
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
    }
    
}
