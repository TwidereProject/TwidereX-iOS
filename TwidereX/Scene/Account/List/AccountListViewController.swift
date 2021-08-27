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
import TwitterSDK

protocol AccountListViewControllerDelegate: AnyObject {
    func signoutTwitterUser(id: TwitterUser.ID)
}

final class AccountListViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: AccountListViewModel!
    
    private(set) lazy var closeBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(AccountListViewController.closeBarButtonItemPressed(_:)))

    private(set) lazy var addBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(AccountListViewController.addBarButtonItemPressed(_:)))
        return barButtonItem
    }()
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(AccountListTableViewCell.self, forCellReuseIdentifier: String(describing: AccountListTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
        
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension AccountListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.ManageAccounts.title
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = closeBarButtonItem
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
            tableView: tableView
        )
        
        addBarButtonItem.target = self
        addBarButtonItem.action = #selector(AccountListViewController.addBarButtonItemPressed(_:))
        
        ThemeService.shared.theme
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.update(theme: theme)
            }
            .store(in: &disposeBag)
    }
    
    private func update(theme: Theme) {
        addBarButtonItem.tintColor = theme.accentColor
    }
    
}

extension AccountListViewController {

    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func addBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let configuration = WelcomeViewModel.Configuration(allowDismissModal: true)
        let welcomeViewModel = WelcomeViewModel(context: context, configuration: configuration)
        coordinator.present(scene: .welcome(viewModel: welcomeViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
    
}

// MARK: - UITableViewDelegate
extension AccountListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .authenticationIndex(record) = item else { return }
        
        Task {
            do {
                let isActive = try await self.context.authenticationService.activeAuthenticationIndex(record: record)
                guard isActive else { return }
                self.coordinator.setup()
            } catch {
                // handle error
                assertionFailure(error.localizedDescription)
            }
        }
    }
}

// MARK: - AccountListTableViewCellDelegate
extension AccountListViewController: AccountListTableViewCellDelegate {
    
    func accountListTableViewCell(_ cell: AccountListTableViewCell, menuButtonPressed button: UIButton) {
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        guard let indexPath = tableView.indexPath(for: cell) else { return }
//        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
//        guard case let .twitterUser(objectID) = item else { return }
//
//        let managedObjectContext = context.managedObjectContext
//        managedObjectContext.perform {
//            guard let twitterUser = managedObjectContext.object(with: objectID) as? TwitterUser else { return }
//            let title = twitterUser.name
//
//            DispatchQueue.main.async { [weak self] in
//                let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
//                let signOutAction = UIAlertAction(title: L10n.Scene.ManageAccounts.deleteAccount.localizedCapitalized, style: .destructive) { [weak self] _ in
//                    guard let self = self else { return }
//                    self.signoutTwitterUser(id: twitterUser.id)
//                }
//                let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
//                alertController.addAction(signOutAction)
//                alertController.addAction(cancelAction)
//                guard let self = self else { return }
//                alertController.popoverPresentationController?.sourceView = button
//                self.present(alertController, animated: true, completion: nil)
//            }
//        }
    }
    
}

// MARK: - AccountListViewControllerDelegate
extension AccountListViewController: AccountListViewControllerDelegate {
    
    func signoutTwitterUser(id: TwitterUser.ID) {
//        let currentAccountCount = viewModel.diffableDataSource.snapshot().itemIdentifiers.count
//        context.authenticationService.signOutTwitterUser(id: id)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] result in
//                guard let self = self else { return }
//                switch result {
//                case .failure(let error):
//                    assertionFailure(error.localizedDescription)
//                case .success(let isSignOut):
//                    guard isSignOut else { return }
//                    self.dismiss(animated: true) {
//                        if currentAccountCount == 1 {
//                            // No active user. Present Authentication scene
//                            let authenticationViewModel = AuthenticationViewModel(isAuthenticationIndexExist: false)
//                            self.coordinator.present(scene: .authentication(viewModel: authenticationViewModel), from: nil, transition: .modal(animated: true, completion: nil))
//                        }
//                    }
//                }
//            }
//            .store(in: &disposeBag)
    }
    
}
