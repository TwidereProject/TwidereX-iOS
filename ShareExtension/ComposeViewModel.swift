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

    var currentPublishProgressObservation: NSKeyValueObservation?

    // input
    let context: AppContext
    
    @Published var authContext: AuthContext?
    @Published var isBusy = false
    @Published var didLoad = false
    
    // output
    @Published var currentPublishProgress: Double = 0

    init(context: AppContext) {
        self.context = context
        // end init
    }
    
}
