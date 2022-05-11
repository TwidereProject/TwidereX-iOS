//
//  TwitterPinBasedAuthenticationViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-17.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import Combine
import WebKit

final class TwitterPinBasedAuthenticationViewModel {
    
    // input
    let authorizeURL: URL
    
    // output
    let pinCodePublisher = PassthroughSubject<String, Never>()
    private var navigationDelegateShim: TwitterPinBasedAuthenticationViewModelNavigationDelegateShim?
    
    init(authorizeURL: URL) {
        self.authorizeURL = authorizeURL
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension TwitterPinBasedAuthenticationViewModel {
    
    var navigationDelegate: WKNavigationDelegate {
        let navigationDelegateShim = TwitterPinBasedAuthenticationViewModelNavigationDelegateShim(viewModel: self)
        self.navigationDelegateShim = navigationDelegateShim
        return navigationDelegateShim
    }
    
}
