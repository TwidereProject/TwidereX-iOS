//
//  TwitterAuthenticationOptionViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine

final class TwitterAuthenticationOptionViewModel: NSObject {
    
    // input
    let context: AppContext
    let consumerKey = CurrentValueSubject<String, Never>("")
    let consumerSecret = CurrentValueSubject<String, Never>("")
    
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
    
    init(context: AppContext) {
        self.context = context
        super.init()
        
        
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
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ListTextFieldTableViewCell.self), for: indexPath) as! ListTextFieldTableViewCell
            _cell.textField.placeholder = option.placeholder
            _cell.input
                .receive(on: DispatchQueue.main)
                .assign(to: \.value, on: consumerKey)
                .store(in: &_cell.disposeBag)
            cell = _cell
        case .consumerSecretTextField:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ListTextFieldTableViewCell.self), for: indexPath) as! ListTextFieldTableViewCell
            _cell.textField.placeholder = option.placeholder
            _cell.input
                .receive(on: DispatchQueue.main)
                .assign(to: \.value, on: consumerSecret)
                .store(in: &_cell.disposeBag)
            cell = _cell
        }
        
        return cell
    }
    
}
