//
//  WelcomeViewModel.swift
//  WelcomeViewModel
//
//  Created by Cirno MainasuK on 2021-8-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import SwiftUI
import Combine
import AppShared
import TwitterSDK
import MastodonSDK
import TwidereCommon

protocol WelcomeViewModelDelegate: AnyObject {
    func presentTwitterAuthenticationOption()
    func welcomeViewModel(_ viewModel: WelcomeViewModel, authenticateTwitter authorizationContextProvider: TwitterAuthorizationContextProvider) async throws
    func welcomeViewModel(_ viewModel: WelcomeViewModel, authenticateMastodon authenticationInfo: MastodonAuthenticationController.MastodonAuthenticationInfo)
}

@MainActor
final class WelcomeViewModel: ObservableObject {
    
    weak var delegate: WelcomeViewModelDelegate?

    // input
    let context: AppContext
    let configuration: Configuration
    @Published var mastodonDomain = ""
    
    // output
    @Published var authenticateMode: AuthenticateMode = .normal
    @Published private(set) var isBusy = false
    @Published private(set) var isAuthenticateTwitter = false
    @Published private(set) var isAuthenticateMastodon = false

    let error = PassthroughSubject<Error, Never>()
    
    init(context: AppContext, configuration: Configuration) {
        self.context = context
        self.configuration = configuration
    }
    
    struct Configuration {
        let allowDismissModal: Bool
    }
    
}

extension WelcomeViewModel {
    enum AuthenticateMode {
        case normal         // default
        case mastodon       // for mastodon domain input
    }
    
    enum WelcomeError: Error, LocalizedError {
        case invalidMastodonDomain
        case invalidAuthenticationToken
        
        var errorDescription: String? {
            switch self {
            case .invalidMastodonDomain:
                return ""
            case .invalidAuthenticationToken:
                return ""
            }
        }
    }
}

extension WelcomeViewModel {
    func authenticateTwitter() async {
        isBusy = true
        isAuthenticateTwitter = true
        
        defer {
            isBusy = false
            isAuthenticateTwitter = false
        }
        
        do {
            try await delegate?.welcomeViewModel(self, authenticateTwitter: AppSecret.default)
        } catch {
            self.error.send(error)
        }
    }
}

extension WelcomeViewModel {
    
    func authenticateMastodon() async {
        switch authenticateMode {
        case .normal:
            authenticateMode = .mastodon
        case .mastodon:
            isBusy = true
            isAuthenticateMastodon = true
            
            defer {
                self.isBusy = false
                self.isAuthenticateMastodon = false
            }
            
            // delay 1s
            try? await Task.sleep(nanoseconds: .second * 1)   // 1s
            guard let domain = MastodonAuthenticationController.parseDomain(from: mastodonDomain) else {
                self.error.send(WelcomeError.invalidMastodonDomain)
                return
            }
            do {
                let redirectedDomain = try await context.apiService.webFinger(domain: domain)
                let applicationResponse = try await context.apiService.createMastodonApplication(domain: redirectedDomain, callbackURI: MastodonAuthenticationController.callbackURL)
                
                let _authenticateInfo = MastodonAuthenticationController.MastodonAuthenticationInfo(
                    domain: redirectedDomain,
                    application: applicationResponse.value,
                    redirectURI: MastodonAuthenticationController.callbackURL
                )
                guard let authenticateInfo = _authenticateInfo else {
                    self.error.send(WelcomeError.invalidAuthenticationToken)
                    return
                }
                
                delegate?.welcomeViewModel(self, authenticateMastodon: authenticateInfo)
            } catch {
                self.error.send(error)
            }
        }
    }

}
