//
//  ComposeViewModel.swift
//  ShareExtension
//
//  Created by MainasuK on 2021/11/17.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import Combine
import TwidereCore

final class ComposeViewModel {
    
    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    @Published var isBusy = false
    @Published var didLoad = false
    
    var currentPublishProgressObservation: NSKeyValueObservation?

    // output
    @Published var author: UserObject?
    @Published var currentPublishProgress: Double = 0

    init(context: AppContext) {
        self.context = context
        // end init
        
        context.authenticationService.activeAuthenticationIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authenticationIndex in
                guard let self = self else { return }
                self.author = authenticationIndex?.user
            }
            .store(in: &disposeBag)
    }
    
}
