//
//  TwitterAuthenticationOptionViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import AppShared
import TwitterSDK
import TwidereCommon

final class TwitterAuthenticationOptionViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let consumerKey = CurrentValueSubject<String, Never>(UserDefaults.shared.twitterAuthenticationConsumerKey ?? "")
    let consumerSecret = CurrentValueSubject<String, Never>(UserDefaults.shared.twitterAuthenticationConsumerSecret ?? "")
    
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
    let appSecret = CurrentValueSubject<AppSecret?, Never>(nil)
    let isSignInBarButtonItemEnabled = CurrentValueSubject<Bool, Never>(true)
    
    init(context: AppContext) {
        self.context = context
        super.init()
        
        consumerKey
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { consumerKey in
                UserDefaults.shared.twitterAuthenticationConsumerKey = consumerKey
            }
            .store(in: &disposeBag)
        
        consumerSecret
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { consumerSecret in
                UserDefaults.shared.twitterAuthenticationConsumerSecret = consumerSecret
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            consumerKey.eraseToAnyPublisher(),
            consumerSecret.eraseToAnyPublisher()
        )
        .map { consumerKey, consumerSecret in
            guard !consumerKey.isEmpty, !consumerSecret.isEmpty else { return nil }
            return AppSecret(
                oauthSecret: AppSecret.OAuthSecret(
                    consumerKey: consumerKey,
                    consumerKeySecret: consumerSecret,
                    clientID: "",   // TODO:
                    hostPublicKey: nil,
                    oauthEndpoint: "oob"
                )
            )
        }
        .assign(to: \.value, on: appSecret)
        .store(in: &disposeBag)
        
        appSecret
            .map { $0 != nil }
            .assign(to: \.value, on: isSignInBarButtonItemEnabled)
            .store(in: &disposeBag)
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
            _cell.textField.text = consumerKey.value
            _cell.input
                .receive(on: DispatchQueue.main)
                .assign(to: \.value, on: consumerKey)
                .store(in: &_cell.disposeBag)
            cell = _cell
        case .consumerSecretTextField:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TableViewTextFieldTableViewCell.self), for: indexPath) as! TableViewTextFieldTableViewCell
            _cell.textField.placeholder = option.placeholder
            _cell.textField.text = consumerSecret.value
            _cell.input
                .receive(on: DispatchQueue.main)
                .assign(to: \.value, on: consumerSecret)
                .store(in: &_cell.disposeBag)
            cell = _cell
        }
        
        return cell
    }
    
}
