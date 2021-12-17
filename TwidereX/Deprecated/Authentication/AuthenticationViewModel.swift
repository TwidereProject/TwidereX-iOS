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
    let isAuthenticationIndexExist: Bool
    
    // output
    let closeBarButtonItemShouldHidden: Bool
    let viewHierarchyShouldReset: Bool
    
    init(isAuthenticationIndexExist: Bool) {
        self.isAuthenticationIndexExist = isAuthenticationIndexExist
        
        self.closeBarButtonItemShouldHidden = !isAuthenticationIndexExist
        self.viewHierarchyShouldReset = isAuthenticationIndexExist
    }

}
