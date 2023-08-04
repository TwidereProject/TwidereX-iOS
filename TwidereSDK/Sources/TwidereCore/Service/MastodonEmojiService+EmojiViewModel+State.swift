//
//  MastodonEmojiService+EmojiViewModel+State.swift
//  
//
//  Created by MainasuK on 2021-11-24.
//

import os.log
import Foundation
import GameplayKit
import MastodonSDK

extension MastodonEmojiService.EmojiViewModel {
    class State: GKState {
        weak var viewModel: MastodonEmojiService.EmojiViewModel?
        
        init(viewModel: MastodonEmojiService.EmojiViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension MastodonEmojiService.EmojiViewModel.State {
    
    class Initial: MastodonEmojiService.EmojiViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self
        }
    }
    
    class Loading: MastodonEmojiService.EmojiViewModel.State {
        let logger = Logger(subsystem: "MastodonEmojiService.EmojiViewModel.State", category: "StateMachine")
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Fail.self || stateClass == Finish.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let viewModel = viewModel,
                  let service = viewModel.service,
                  let stateMachine = stateMachine
            else { return }
            
            Task {
                do {
                    let response = try await Mastodon.API.CustomEmoji.emojis(
                        session: service.session,
                        domain: viewModel.domain
                    )
                    
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): load \(response.value.count) emojis for \(viewModel.domain)")
                    stateMachine.enter(Finish.self)
                    viewModel.emojis = response.value
                } catch {
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: failed to load custom emojis for %s: %s. Retry 10s later", ((#file as NSString).lastPathComponent), #line, #function, viewModel.domain, error.localizedDescription)
                    stateMachine.enter(Fail.self)
                }
            }
        }
    }
    
    class Fail: MastodonEmojiService.EmojiViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Loading.self || stateClass == Finish.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let stateMachine = stateMachine else { return }
            
            // retry 10s later
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                stateMachine.enter(Loading.self)
            }
        }
    }
    
    class Finish: MastodonEmojiService.EmojiViewModel.State {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // one time task
            return false
        }
    }

}
