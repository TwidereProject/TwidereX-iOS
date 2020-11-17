//
//  TwitterPinBasedAuthenticationViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-17.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import Combine

final class TwitterPinBasedAuthenticationViewModel {
    
    // input
    let authenticateURL: URL
    
    // output
    let pinCodePublisher = PassthroughSubject<String, Never>()
    
    init(authenticateURL: URL) {
        self.authenticateURL = authenticateURL
    }
    
}
