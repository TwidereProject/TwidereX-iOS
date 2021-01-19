//
//  AuthenticationViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

final class AuthenticationViewModel {
    
    // input
    let isCloseBarButtonItemHidden: Bool
    
    init(isCloseBarButtonItemHidden: Bool = false) {
        self.isCloseBarButtonItemHidden = isCloseBarButtonItemHidden
    }

}
