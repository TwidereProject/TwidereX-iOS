//
//  TwitterAuthenticationOptionViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import TwitterSDK

final class TwitterAuthenticationOptionViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    
    @Published var consumerKey: String = UserDefaults.shared.twitterAuthenticationConsumerKey ?? ""
    @Published var consumerSecret: String = UserDefaults.shared.twitterAuthenticationConsumerSecret ?? ""
    @Published var clientID: String = AppSecret.default.oauthSecret.clientID
    
    // output
    let sections: [Section] = [
        Section(
            header: L10n.Scene.SignIn.TwitterOptions.signInWithCustomTwitterKey,
            footer: L10n.Scene.SignIn.TwitterOptions.twitterApiV2AccessIsRequired,
            options: [
                .consumerKeyTextField,
                .consumerSecretTextField,
            ]
        )
    ]
    @Published var isSignInBarButtonItemEnabled = false
    
    init(context: AppContext) {
        self.context = context
        super.init()
        
        $consumerKey
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { consumerKey in
                UserDefaults.shared.twitterAuthenticationConsumerKey = consumerKey
            }
            .store(in: &disposeBag)
        
        $consumerSecret
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { consumerSecret in
                UserDefaults.shared.twitterAuthenticationConsumerSecret = consumerSecret
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            $consumerKey,
            $consumerSecret
        )
        .receive(on: DispatchQueue.main)
        .map { consumerKey, consumerSecret -> Bool in
            guard !consumerKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !consumerSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return false }
            return true
        }
        .assign(to: &$isSignInBarButtonItemEnabled)
    }
}

extension TwitterAuthenticationOptionViewModel {
    
    enum Option {
        case consumerKeyTextField
        case consumerSecretTextField
        
        var placeholder: String? {
            switch self {
            case .consumerKeyTextField:         return "Consumer Key"       // should not i18n this string
            case .consumerSecretTextField:      return "Consumer Secret"    // should not i18n this string
            }
        }
    }
    
    struct Section {
        let header: String?
        let footer: String?
        let options: [Option]
    }
    
}

extension TwitterAuthenticationOptionViewModel: UITableViewDataSource {
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        let option = sections[indexPath.section].options[indexPath.row]
        switch option {
        case .consumerKeyTextField:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TableViewTextFieldTableViewCell.self), for: indexPath) as! TableViewTextFieldTableViewCell
            _cell.textField.placeholder = option.placeholder
            _cell.textField.text = consumerKey
            _cell.input
                .receive(on: DispatchQueue.main)
                .assign(to: \.consumerKey, on: self)
                .store(in: &_cell.disposeBag)
            cell = _cell
        case .consumerSecretTextField:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TableViewTextFieldTableViewCell.self), for: indexPath) as! TableViewTextFieldTableViewCell
            _cell.textField.placeholder = option.placeholder
            _cell.textField.text = consumerSecret
            _cell.input
                .receive(on: DispatchQueue.main)
                .assign(to: \.consumerSecret, on: self)
                .store(in: &_cell.disposeBag)
            cell = _cell
        }
        
        return cell
    }
    
}

// MARK: - TwitterAuthorizationContextProvider
extension TwitterAuthenticationOptionViewModel: TwitterAuthorizationContextProvider {
    var oauth: Twitter.AuthorizationContext.OAuth.Context {
        return .standard(.init(
            consumerKey: consumerKey,
            consumerKeySecret: consumerSecret)
        )
    }
    
    var oauth2: Twitter.AuthorizationContext.OAuth2.Context {
        assert(consumerKey == "DEBUG")
        return .relay(.init(
            clientID: clientID,
            consumerKey: AppSecret.default.oauthSecret.consumerKey,
            consumerKeySecret: AppSecret.default.oauthSecret.consumerKeySecret,
            endpoint: URL(string: AppSecret.default.oauthSecret.oauth2Endpoint)!,
            hostPublicKey: AppSecret.default.oauthSecret.hostPublicKey!
        ))
    }
    
    
}
