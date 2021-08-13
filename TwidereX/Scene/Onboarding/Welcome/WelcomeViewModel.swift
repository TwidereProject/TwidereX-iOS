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

protocol WelcomeViewModelDelegate: AnyObject {
    func presentTwitterAuthenticationOption()
    func welcomeViewModel(_ viewModel: WelcomeViewModel, authenticateRequestTokenResponse exchange: Twitter.API.OAuth.OAuthRequestTokenResponseExchange)
}

@MainActor
final class WelcomeViewModel: ObservableObject {
    
    weak var delegate: WelcomeViewModelDelegate?
    
    // input
    let context: AppContext
    @Published var mastodonDomain = ""
    
    // output
    @Published var authenticateMode: AuthenticateMode = .normal
    @Published private(set) var isBusy = false
    @Published private(set) var isAuthenticateTwitter = false
    @Published private(set) var isAuthenticateMastodon = false

    let error = PassthroughSubject<Error, Never>()
    
    init(context: AppContext) {
        self.context = context
    }
    
}

extension WelcomeViewModel {
    enum AuthenticateMode {
        case normal         // default
        case mastodon       // for mastodon domain input
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
            let requestTokenResponse = try await context.apiService.twitterRequestToken(provider: AppSecret.default)
            delegate?.welcomeViewModel(self, authenticateRequestTokenResponse: requestTokenResponse)
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
                isBusy = false
                isAuthenticateMastodon = false
            }
            
            do {
                // TODO:
            } catch {
                
            }

        }
    }
    
    static func parseDomain(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }
        
        let urlString = trimmed.hasPrefix("https://") ? trimmed : "https://" + trimmed
        guard let url = URL(string: urlString),
              let host = url.host else {
                  return nil
              }
        let components = host.components(separatedBy: ".")
        guard !components.contains(where: { $0.isEmpty }) else { return nil }
        guard components.count >= 2 else { return nil }
        
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: input host: %s", ((#file as NSString).lastPathComponent), #line, #function, host)
        
        return host
    }
    
}
