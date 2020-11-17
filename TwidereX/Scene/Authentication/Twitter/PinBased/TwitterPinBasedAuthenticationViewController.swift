//
//  TwitterPinBasedAuthenticationViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-17.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import WebKit

final class TwitterPinBasedAuthenticationViewController: UIViewController, NeedsDependency {
        
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: TwitterPinBasedAuthenticationViewModel!
    
    let webView = WKWebView()
}

extension TwitterPinBasedAuthenticationViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Authentication"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(TwitterPinBasedAuthenticationViewController.cancelBarButtonItemPressed(_:)))
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: authenticate via: %s", ((#file as NSString).lastPathComponent), #line, #function, viewModel.authenticateURL.debugDescription)
        webView.navigationDelegate = self
        webView.load(URLRequest(url: viewModel.authenticateURL))
    }
    
}

extension TwitterPinBasedAuthenticationViewController {
    
    @objc private func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - WKNavigationDelegate
extension TwitterPinBasedAuthenticationViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        webView.evaluateJavaScript("document.querySelector('#oauth_pin code').textContent", completionHandler: { [weak self] (any, error) in
            guard let self = self else { return }
            guard error == nil else { return }
            guard let pinCode = any as? String else { return }
            self.viewModel.pinCodePublisher.send(pinCode)
            self.dismiss(animated: true, completion: nil)
        })
    }
    
}
