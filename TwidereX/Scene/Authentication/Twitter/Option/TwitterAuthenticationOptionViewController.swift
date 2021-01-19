//
//  TwitterAuthenticationOptionViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import TwitterAPI
import AuthenticationServices

final class TwitterAuthenticationOptionViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: TwitterAuthenticationOptionViewModel!
    
    let signInBarButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.signIn, style: .done, target: nil, action: nil)
    let activityIndicatorBarButtonItem = UIBarButtonItem.activityIndicatorBarButtonItem
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(ListTextFieldTableViewCell.self, forCellReuseIdentifier: String(describing: ListTextFieldTableViewCell.self))
        return tableView
    }()
    
    private var twitterAuthenticationController: TwitterAuthenticationController?
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension TwitterAuthenticationOptionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem.cancelBarButtonItem(target: self, action: #selector(TwitterAuthenticationOptionViewController.cancelBarButtonItemPressed(_:)))
        navigationItem.rightBarButtonItem = signInBarButtonItem
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        tableView.dataSource = viewModel

        signInBarButtonItem.target = self
        signInBarButtonItem.action = #selector(TwitterAuthenticationOptionViewController.signInBarButtonItemPressed(_:))

        viewModel.isSignInBarButtonItemEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: signInBarButtonItem)
            .store(in: &disposeBag)
    }

}

extension TwitterAuthenticationOptionViewController {

    @objc private func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        dismiss(animated: true, completion: nil)
    }
    
    @objc private func signInBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        guard let appSecret = viewModel.appSecret.value else {
            // handle error
            return
        }
        
        context.apiService.twitterRequestToken(withOAuthExchangeProvider: viewModel)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in
                guard let self = self else { return }
                self.navigationItem.rightBarButtonItem = self.activityIndicatorBarButtonItem
            })
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: request token error: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    self.navigationItem.rightBarButtonItem = self.signInBarButtonItem
                    let alertController = UIAlertController.standardAlert(of: error)
                    self.present(alertController, animated: true)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] requestTokenExchange in
                guard let self = self else { return }
                self.twitterAuthenticate(requestTokenExchange: requestTokenExchange, appSecret: appSecret)
            }
            .store(in: &disposeBag)
    }
    
}

extension TwitterAuthenticationOptionViewController {
    private func twitterAuthenticate(
        requestTokenExchange: Twitter.API.OAuth.OAuthRequestTokenExchange,
        appSecret: AppSecret
    ) {
        let requestToken: String = {
            switch requestTokenExchange {
            case .requestTokenResponse(let response):           return response.oauthToken
            case .customRequestTokenResponse(_, let append):    return append.requestToken
            }
        }()
        let authenticateURL = Twitter.API.OAuth.autenticateURL(requestToken: requestToken)
        
        twitterAuthenticationController = TwitterAuthenticationController(
            context: context,
            coordinator: coordinator,
            appSecret: appSecret,
            authenticateURL: authenticateURL,
            requestTokenExchange: requestTokenExchange
        )
        
        twitterAuthenticationController?.isAuthenticating
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isAuthenticating in
                guard let self = self else { return }
                if !isAuthenticating {
                    self.navigationItem.rightBarButtonItem = self.signInBarButtonItem
                }
            })
            .store(in: &disposeBag)
        
        twitterAuthenticationController?.error
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] error in
                guard let self = self else { return }
                guard let error = error else { return }
                let alertController = UIAlertController.standardAlert(of: error)
                self.present(alertController, animated: true)
            })
            .store(in: &disposeBag)
        
        twitterAuthenticationController?.authenticated
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] twitterUser in
                guard let self = self else { return }
                self.context.authenticationService.activeTwitterUser(id: twitterUser.idStr)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .failure(let error):
                            assertionFailure(error.localizedDescription)
                        case .success(let isActived):
                            assert(isActived)
                            self.coordinator.setup()
                        }
                    }
                    .store(in: &self.disposeBag)
            })
            .store(in: &disposeBag)
        
        twitterAuthenticationController?.authenticationSession?.prefersEphemeralWebBrowserSession = true
        twitterAuthenticationController?.authenticationSession?.presentationContextProvider = self
        twitterAuthenticationController?.authenticationSession?.start()
    }
    
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension TwitterAuthenticationOptionViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}


// MARK: - UITableViewDelegate
extension TwitterAuthenticationOptionViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < viewModel.sections.count else { return nil }
        let section = viewModel.sections[section]
        
        guard let header = section.header else { return nil }
        let headerView = TableViewSectionTextHeaderView()
        headerView.headerLabel.text = header
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section < viewModel.sections.count else { return nil }
        let section = viewModel.sections[section]
        
        guard let footer = section.footer else { return nil }
        let footerView = TableViewSectionTextHeaderView()
        footerView.headerLabel.text = footer
        footerView.headerLabel.font = .preferredFont(forTextStyle: .footnote)
        return footerView
    }
    
}
