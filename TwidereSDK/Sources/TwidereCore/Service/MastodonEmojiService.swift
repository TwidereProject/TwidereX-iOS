//
//  MastodonEmojiService.swift
//  
//
//  Created by MainasuK on 2021-11-24.
//

import os.log
import Foundation
import Combine
import MastodonSDK

public final class MastodonEmojiService {
    
    public let session = URLSession.shared
    
    public let workingQueue = DispatchQueue(label: "com.twidere.TwidereX.MastodonEmojiService.working-queue")
    private(set) var emojiViewModelDict: [String: EmojiViewModel] = [:]
    
    public init() { }
    
}

extension MastodonEmojiService {

    public func dequeueEmojiViewModel(for domain: String) -> EmojiViewModel? {
        var _emojiViewModel: EmojiViewModel?
        workingQueue.sync {
            if let viewModel = emojiViewModelDict[domain] {
                _emojiViewModel = viewModel
            } else {
                let viewModel = EmojiViewModel(domain: domain, service: self)
                _emojiViewModel = viewModel
                
                Task {
                    // trigger loading
                    await viewModel.stateMachine.enter(EmojiViewModel.State.Loading.self)                    
                }
            }
        }
        return _emojiViewModel
    }
    
}

