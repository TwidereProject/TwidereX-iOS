//
//  AccountListViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/11.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import AuthenticationServices
import Combine
import CoreDataStack
import TwitterAPI

protocol AccountListViewControllerDelegate: class {
    func signoutTwitterUser(id: TwitterUser.ID)
}

final class AccountListViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: AccountListViewModel!
    
    let addBarButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.add, style: .done, target: self, action: #selector(AccountListViewController.addBarButtonItemPressed(_:)))
    let activityIndicatorBarButtonItem: UIBarButtonItem = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        let barButtonItem = UIBarButtonItem(customView: activityIndicatorView)
        activityIndicatorView.startAnimating()
        return barButtonItem
    }()
    
    lazy var tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(AccountListTableViewCell.self, forCellReuseIdentifier: String(describing: AccountListTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private var twitterAuthenticationController: TwitterAuthenticationController?
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension AccountListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.ManageAccounts.title
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.cancel, style: .plain, target: self, action: #selector(AccountListViewController.closeBarButtonItemPressed(_:)))
        navigationItem.rightBarButtonItem = addBarButtonItem
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            for: tableView,
            dependency: self,
            accountListTableViewCellDelegate: self,
            accountListViewControllerDelegate: self
        )
        
        addBarButtonItem.target = self
        addBarButtonItem.action = #selector(AccountListViewController.addBarButtonItemPressed(_:))
    }
    
}

extension AccountListViewController {

    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func addBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        context.apiService.twitterRequestToken()
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
                    self.navigationItem.rightBarButtonItem = self.addBarButtonItem
                    let alertController = UIAlertController.standardAlert(of: error)
                    self.present(alertController, animated: true)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] requestTokenExchange in
                guard let self = self else { return }
                self.twitterAuthenticate(requestTokenExchange: requestTokenExchange)
            }
            .store(in: &disposeBag)
    }
    
}

extension AccountListViewController {
    func twitterAuthenticate(requestTokenExchange: Twitter.API.OAuth.OAuthRequestTokenExchange) {
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
            authenticateURL: authenticateURL,
            requestTokenExchange: requestTokenExchange
        )
        
        twitterAuthenticationController?.isAuthenticating
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isAuthenticating in
                guard let self = self else { return }
                if !isAuthenticating {
                    self.navigationItem.rightBarButtonItem = self.addBarButtonItem
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
extension AccountListViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}

// MARK: - UITableViewDelegate
extension AccountListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .twitterUser(objectID) = item else { return }
        
        let managedObjectContext = context.managedObjectContext
        managedObjectContext.perform {
            guard let twitterUser = managedObjectContext.object(with: objectID) as? TwitterUser else { return }
            self.context.authenticationService.activeTwitterUser(id: twitterUser.id)
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
        }
    }
    
}

// MARK: - AccountListTableViewCellDelegate
extension AccountListViewController: AccountListTableViewCellDelegate {
    
    func accountListTableViewCell(_ cell: AccountListTableViewCell, menuButtonPressed button: UIButton) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .twitterUser(objectID) = item else { return }
        
        let managedObjectContext = context.managedObjectContext
        managedObjectContext.perform {
            guard let twitterUser = managedObjectContext.object(with: objectID) as? TwitterUser else { return }
            let title = twitterUser.name
         
            DispatchQueue.main.async { [weak self] in
                let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
                let signOutAction = UIAlertAction(title: L10n.Scene.ManageAccounts.deleteAccount.localizedCapitalized, style: .destructive) { [weak self] _ in
                    guard let self = self else { return }
                    self.signoutTwitterUser(id: twitterUser.id)
                }
                let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
                alertController.addAction(signOutAction)
                alertController.addAction(cancelAction)
                guard let self = self else { return }
                alertController.popoverPresentationController?.sourceView = button
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
}

// MARK: - AccountListViewControllerDelegate
extension AccountListViewController: AccountListViewControllerDelegate {
    
    func signoutTwitterUser(id: TwitterUser.ID) {
        let currentAccountCount = viewModel.diffableDataSource.snapshot().itemIdentifiers.count
        context.authenticationService.signOutTwitterUser(id: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    assertionFailure(error.localizedDescription)
                case .success(let isSignOut):
                    guard isSignOut else { return }
                    self.dismiss(animated: true) {
                        if currentAccountCount == 1 {
                            self.coordinator.present(scene: .authentication, from: nil, transition: .modal(animated: true, completion: nil))
                        }
                    }
                }
            }
            .store(in: &disposeBag)
    }
    
}
