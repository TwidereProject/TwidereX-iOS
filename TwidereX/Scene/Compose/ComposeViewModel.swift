//
//  ComposeViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/17.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import Combine
import TwidereCore
import TwidereLocalization

final class ComposeViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    @Published public var viewLayoutFrame = ViewLayoutFrame()
    
    // output
    @Published var title = L10n.Scene.Compose.Title.compose
    
    init(context: AppContext) {
        self.context = context
        // end init
    }
    
}
