//
//  WelcomeViewController.swift
//  WelcomeViewController
//
//  Created by Cirno MainasuK on 2021-8-11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import Combine
import AppShared
import TwitterSDK
import MastodonSDK
import AuthenticationServices

final class WelcomeViewController: UIViewController, NeedsDependency {
        
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    let logger = Logger(subsystem: "WelcomeViewController", category: "UI")
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: WelcomeViewModel!
    
    private var twitterAuthenticationController: TwitterAuthenticationController?
    private var mastodonAuthenticationController: MastodonAuthenticationController?

    private(set) lazy var closeBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(WelcomeViewController.closeBarButtonItemPressed(_:)))

    private(set) lazy var backBarButtonItem: UIBarButtonItem = {
        let image = Asset.Arrows.arrowLeft.image.withRenderingMode(.alwaysTemplate)
        let item = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(WelcomeViewController.backBarButtonItemPressed(_:)))
        item.tintColor = .label
        return item
    }()
    
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension WelcomeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        navigationItem.standardAppearance = navigationBarAppearance
        navigationItem.compactAppearance = navigationBarAppearance
        navigationItem.compactScrollEdgeAppearance = navigationBarAppearance
        navigationItem.scrollEdgeAppearance = navigationBarAppearance
        
        let hostingController = UIHostingController(rootView: WelcomeView().environmentObject(viewModel))
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.view.frame = view.bounds
        view.addSubview(hostingController.view)
        
        viewModel.delegate = self
        
        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self = self else { return }
                let alertController = UIAlertController.standardAlert(of: error)
                self.present(alertController, animated: true)
            }
            .store(in: &disposeBag)
        
        viewModel.$authenticateMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authenticateMode in
                guard let self = self else { return }
                switch authenticateMode {
                case .normal:
                    self.navigationItem.leftBarButtonItem = self.viewModel.configuration.allowDismissModal ? self.closeBarButtonItem : nil
                case .mastodon:
                    self.navigationItem.leftBarButtonItem = self.backBarButtonItem
                }
            }
            .store(in: &disposeBag)
    }
    
}

extension WelcomeViewController {
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func backBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        switch viewModel.authenticateMode {
        case .normal:
            break
        case .mastodon:
            viewModel.authenticateMode = .normal
        }
    }
}

// MARK: - WelcomeViewModelDelegate
extension WelcomeViewController: WelcomeViewModelDelegate {
    
    // For user PIN-based OAuth Twitter authentication (WebView)
    func presentTwitterAuthenticationOption() {
        let twitterAuthenticationOptionViewModel = TwitterAuthenticationOptionViewModel(context: context)
        coordinator.present(scene: .twitterAuthenticationOption(viewModel: twitterAuthenticationOptionViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
    
    // For app custom OAuth Twitter authentication (AuthenticationServices)
    func welcomeViewModel(
        _ viewModel: WelcomeViewModel,
        authenticateTwitter exchange: Twitter.API.OAuth.OAuthRequestTokenResponseExchange
    ) {
        let requestToken: String = {
            switch exchange {
            case .pin(let response):            return response.oauthToken
            case .custom(_, let append):        return append.requestToken
            }
        }()
        let authenticateURL = Twitter.API.OAuth.authenticateURL(requestToken: requestToken)

        let authenticationController = TwitterAuthenticationController(
            context: context,
            coordinator: coordinator,
            appSecret: AppSecret.default,
            authenticateURL: authenticateURL,
            requestTokenExchange: exchange
        )
        
        authenticationController.isAuthenticating
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isAuthenticating in
                guard let _ = self else { return }
                // do nothing
            })
            .store(in: &authenticationController.disposeBag)
        
        authenticationController.error
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] error in
                guard let self = self else { return }
                guard let error = error else { return }
                let alertController = UIAlertController.standardAlert(of: error)
                self.present(alertController, animated: true)
            })
            .store(in: &authenticationController.disposeBag)
        
        authenticationController.authenticated
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] twitterUser in
                guard let self = self else { return }
                Task {
                    do {
                        let userID = twitterUser.idStr
                        let isActive = try await self.context.authenticationService.activeTwitterUser(userID: userID)
                        
                        // active user and reset view hierarchy
                        guard isActive else { return }
                        self.coordinator.setup()
                    } catch {
                        // TODO: handle error
                        assertionFailure()
                    }
                }
            })
            .store(in: &authenticationController.disposeBag)
        
        self.twitterAuthenticationController = authenticationController
        assert(authenticationController.authenticationSession != nil)
        authenticationController.authenticationSession?.prefersEphemeralWebBrowserSession = true
        authenticationController.authenticationSession?.presentationContextProvider = self
        authenticationController.authenticationSession?.start()
    }
    
    // For PIN-Based OAuth Mastodon authentication (AuthenticationServices)
    func welcomeViewModel(
        _ viewModel: WelcomeViewModel,
        authenticateMastodon authenticationInfo: MastodonAuthenticationController.MastodonAuthenticationInfo
    ) {
        let authenticationController = MastodonAuthenticationController(
            context: context,
            coordinator: coordinator,
            authenticationInfo: authenticationInfo,
            appSecret: AppSecret.default
        )
        
        authenticationController.isAuthenticating
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isAuthenticating in
                guard let _ = self else { return }
                // do nothing
            })
            .store(in: &authenticationController.disposeBag)
        
        authenticationController.error
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] error in
                guard let self = self else { return }
                guard let error = error else { return }
                let alertController = UIAlertController.standardAlert(of: error)
                self.present(alertController, animated: true)
            })
            .store(in: &authenticationController.disposeBag)
        
        authenticationController.authenticated
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] mastodonUser in
                guard let self = self else { return }
                Task {
                    do {
                        let domain = authenticationInfo.domain
                        let userID = mastodonUser.id
                        let isActive = try await self.context.authenticationService.activeMastodonUser(domain: domain, userID: userID)
                        
                        // active user and reset view hierarchy
                        guard isActive else { return }
                        self.coordinator.setup()
                    } catch {
                        // TODO: handle error
                        assertionFailure()
                    }
                }
            })
            .store(in: &authenticationController.disposeBag)
        
        self.mastodonAuthenticationController = authenticationController
        authenticationController.authenticationSession?.presentationContextProvider = self
        authenticationController.authenticationSession?.start()
    }
    
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension WelcomeViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .fullScreen
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension WelcomeViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}
