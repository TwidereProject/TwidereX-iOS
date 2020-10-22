//
//  ComposeTweetViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import Combine
import CoreDataStack
import twitter_text

final class ComposeTweetViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let twitterTextParser = TwitterTextParser.defaultParser()
    let currentTwitterAuthentication = CurrentValueSubject<TwitterAuthentication?, Never>(nil)
    let composeContent = CurrentValueSubject<String, Never>("")

    // output
    let avatarImageURL = CurrentValueSubject<URL?, Never>(nil)
    let isAvatarLockHidden = CurrentValueSubject<Bool, Never>(true)
    let twitterTextparseResults = CurrentValueSubject<TwitterTextParseResults, Never>(.init())
    
    init(context: AppContext) {
        self.context = context
        
        composeContent
            .map { text in self.twitterTextParser.parseTweet(text) }
            .assign(to: \.value, on: twitterTextparseResults)
            .store(in: &disposeBag)
        
        twitterTextparseResults.print().sink { _ in }.store(in: &disposeBag)
    }
    
}
