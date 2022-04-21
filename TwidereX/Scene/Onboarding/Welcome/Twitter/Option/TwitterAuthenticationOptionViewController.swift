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
import AppShared
import AuthenticationServices
import TwitterSDK
import TwidereUI

final class TwitterAuthenticationOptionViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: TwitterAuthenticationOptionViewModel!
    
    let signInBarButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.signIn, style: .done, target: nil, action: nil)
    let activityIndicatorBarButtonItem = UIBarButtonItem.activityIndicatorBarButtonItem
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(TableViewTextFieldTableViewCell.self, forCellReuseIdentifier: String(describing: TableViewTextFieldTableViewCell.self))
        tableView.tableHeaderView = UITableView.groupedTableViewPaddingHeaderView
        return tableView
    }()
    
    private var twitterAuthenticationController: TwitterAuthenticationController?
    private var requestTokenExchangeTask: Task<(), Never>?
    
    deinit {
        requestTokenExchangeTask?.cancel()
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
            assertionFailure()
            return
        }
        
        requestTokenExchangeTask = Task {
            self.navigationItem.rightBarButtonItem = self.activityIndicatorBarButtonItem
            do {
                let requestTokenExchange = try await self.context.apiService.twitterOAuthRequestToken(provider: appSecret)
                if Task.isCancelled { return }
                self.twitterAuthenticate(
                    appSecret: appSecret,
                    authorizationContext: .oauth(requestTokenExchange)
                )
            } catch {
                os_log("%{public}s[%{public}ld], %{public}s: request token error: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                self.navigationItem.rightBarButtonItem = self.signInBarButtonItem
                if Task.isCancelled { return }
                let alertController = UIAlertController.standardAlert(of: error)
                self.present(alertController, animated: true)
            }
        }
    }
    
}

extension TwitterAuthenticationOptionViewController {
    private func twitterAuthenticate(
        appSecret: AppSecret,
        authorizationContext: TwitterAuthenticationController.AuthorizationContext
    ) {
        let authenticationController = TwitterAuthenticationController(
            context: context,
            coordinator: coordinator,
            appSecret: appSecret,
            authorizationContext: authorizationContext
        )
        
        authenticationController.isAuthenticating
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isAuthenticating in
                guard let self = self else { return }
                if !isAuthenticating {
                    self.navigationItem.rightBarButtonItem = self.signInBarButtonItem
                }
            })
            .store(in: &disposeBag)
        
        authenticationController.error
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] error in
                guard let self = self else { return }
                guard let error = error else { return }
                let alertController = UIAlertController.standardAlert(of: error)
                self.present(alertController, animated: true)
            })
            .store(in: &disposeBag)
        
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
            .store(in: &disposeBag)
        twitterAuthenticationController = authenticationController
        authenticationController.authenticationSession?.prefersEphemeralWebBrowserSession = true
        authenticationController.authenticationSession?.presentationContextProvider = self
        authenticationController.authenticationSession?.start()
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
        headerView.label.text = header
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section < viewModel.sections.count else { return nil }
        let section = viewModel.sections[section]
        
        guard let footer = section.footer else { return nil }
        let footerView = TableViewSectionTextHeaderView()
        footerView.label.text = footer
        footerView.label.font = .preferredFont(forTextStyle: .footnote)
        return footerView
    }
    
}
