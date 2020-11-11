//
//  AccountListViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/11.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack

final class AccountListViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: AccountListViewModel!
    
    lazy var tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(AccountListTableViewCell.self, forCellReuseIdentifier: String(describing: AccountListTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
}

extension AccountListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Accounts"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(AccountListViewController.closeBarButtonItemPressed(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, target: self, action: #selector(AccountListViewController.closeBarButtonItemPressed(_:)))
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        viewModel.accountListTableViewCellDelegate = self
        viewModel.setupDiffableDataSource(for: tableView)
    }
    
}

extension AccountListViewController {

    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func addBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
    }
    
}

// MARK: - UITableViewDelegate
extension AccountListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}

// MARK: - AccountListTableViewCellDelegate
extension AccountListViewController: AccountListTableViewCellDelegate {
    
    func accountListTableViewCell(_ cell: AccountListTableViewCell, menuButtonPressed button: UIButton) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .twittertUser(objectID) = item else { return }
        
        let managedObjectContext = context.managedObjectContext
        managedObjectContext.perform {
            guard let twitterUser = managedObjectContext.object(with: objectID) as? TwitterUser else { return }
            let title = twitterUser.name
         
            DispatchQueue.main.async { [weak self] in
                let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
                let signOutAction = UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
                    guard let self = self else { return }
                    self.signoutTwitterUser(id: twitterUser.id)
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alertController.addAction(signOutAction)
                alertController.addAction(cancelAction)
                guard let self = self else { return }
                alertController.popoverPresentationController?.sourceView = button
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    private func signoutTwitterUser(id: TwitterUser.ID) {
//        context.authenticationService.signOutTwitterUser(id: id)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] result in
//                guard let self = self else { return }
//                switch result {
//                case .failure(let error):
//                    // TODO:
//                    break
//                case .success:
//                    self.dismiss(animated: true) {
//                        self.coordinator.present(scene: .authentication, from: nil, transition: .modal(animated: true, completion: nil))                        
//                    }
//                }
//            }
//            .store(in: &disposeBag)
    }
    
}
