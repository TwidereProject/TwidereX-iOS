//
//  ComposeViewModel.swift
//  ShareExtension
//
//  Created by MainasuK on 2021/11/17.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import TwidereUI

final class ComposeViewModel {
    
    // input
    
    // output
    @Published var author: UserObject?
    @Published var title = L10n.Scene.Compose.Title.compose
    
    init() {
        
        
    }
    
}
