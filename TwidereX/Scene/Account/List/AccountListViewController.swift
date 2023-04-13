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

final class AccountListViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    let logger = Logger(subsystem: "AccountListViewController", category: "ViewController")
    
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
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
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
            tableView: tableView,
            userViewTableViewCellDelegate: self
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
                self.coordinator.setup(authentication: record)
            } catch {
                // handle error
                assertionFailure(error.localizedDescription)
            }
        }
    }
}

// MARK: - AuthContextProvider
extension AccountListViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - UserViewTableViewCellDelegate
extension AccountListViewController: UserViewTableViewCellDelegate { }

// MARK: - UIAdaptivePresentationControllerDelegate
extension AccountListViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        switch traitCollection.userInterfaceIdiom {
        case .phone:
            return .automatic
        default:
            return .formSheet
        }
    }
}
