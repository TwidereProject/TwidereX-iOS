//
//  WKNavigationDelegateShim.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-21.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import WebKit

final class TwitterPinBasedAuthenticationViewModelNavigationDelegateShim: NSObject {
    
    weak var viewModel: TwitterPinBasedAuthenticationViewModel?
    
    init(viewModel: TwitterPinBasedAuthenticationViewModel) {
        self.viewModel = viewModel
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
}


// MARK: - WKNavigationDelegate
extension TwitterPinBasedAuthenticationViewModelNavigationDelegateShim: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        webView.evaluateJavaScript("document.querySelector('#oauth_pin code').textContent", completionHandler: { [weak self] (any, error) in
            guard let self = self, let viewModel = self.viewModel else { return }
            guard error == nil else { return }
            guard let pinCode = any as? String else { return }
            viewModel.pinCodePublisher.send(pinCode)
        })
    }
    
}

