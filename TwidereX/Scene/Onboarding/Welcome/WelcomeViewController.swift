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
    
    let logger = Logger(subsystem: "WelcomeViewController", category: "ViewController")
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: WelcomeViewModel!
    
    private var twitterAuthenticationController: TwitterAuthenticationController?
    private var mastodonAuthenticationController: MastodonAuthenticationController?

    private(set) lazy var closeBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(WelcomeViewController.closeBarButtonItemPressed(_:)))
        item.accessibilityLabel = L10n.Accessibility.Common.close
        return item
    }()

    private(set) lazy var backBarButtonItem: UIBarButtonItem = {
        let image = Asset.Arrows.arrowLeft.image.withRenderingMode(.alwaysTemplate)
        let item = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(WelcomeViewController.backBarButtonItemPressed(_:)))
        item.tintColor = .label
        item.accessibilityLabel = L10n.Accessibility.Common.back
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

    // For user customized Twitter Token authentication
    func presentTwitterAuthenticationOption() {
        let twitterAuthenticationOptionViewModel = TwitterAuthenticationOptionViewModel(context: context)
        coordinator.present(
            scene: .twitterAuthenticationOption(viewModel: twitterAuthenticationOptionViewModel),
            from: self,
            transition: .modal(animated: true, completion: nil)
        )
    }
    
    // For app OAuth Twitter authentication (AuthenticationServices)
    func welcomeViewModel(
        _ viewModel: WelcomeViewModel,
        authenticateTwitter authorizationContextProvider: TwitterAuthorizationContextProvider
    ) async throws {
        let authenticationController = TwitterAuthenticationController(
            context: context,
            coordinator: coordinator
        )
        
        // bind UI
        authenticationController.$isAuthenticating
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isAuthenticating in
                guard let _ = self else { return }
                // do nothing
            })
            .store(in: &authenticationController.disposeBag)
        
        // bind error
        authenticationController.$error
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] error in
                guard let self = self else { return }
                guard let error = error else { return }
                let alertController = UIAlertController.standardAlert(of: error)
                self.present(alertController, animated: true)
            })
            .store(in: &authenticationController.disposeBag)
        
        // bind view hierarchy
        authenticationController.$authenticatedTwitterUser
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] twitterUser in
                guard let self = self else { return }
                guard let twitterUser = twitterUser else { return }
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
        
        // bind OAuth action
        // - Pin-based OAuth
        authenticationController.$twitterPinBasedAuthenticationViewController
            .receive(on: DispatchQueue.main)
            .sink { [weak self] viewController in
                guard let self = self else { return }
                guard let viewController = viewController else { return }
                let navigationController = AdaptiveStatusBarStyleNavigationController(rootViewController: viewController)
                self.present(navigationController, animated: true)
            }
            .store(in: &disposeBag)
        // - 3-legged OAuth
        authenticationController.$authenticationSession
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authenticationSession in
                guard let self = self else { return }
                guard let authenticationSession = authenticationSession else { return }
                authenticationSession.prefersEphemeralWebBrowserSession = false
                authenticationSession.presentationContextProvider = self
                authenticationSession.start()
            }
            .store(in: &disposeBag)
        
        // setup TwitterAuthenticationController
        try await authenticationController.setup(authorizationContext: .oauth(authorizationContextProvider.oauth))

        // store authenticationController
        self.twitterAuthenticationController = authenticationController
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
