//
//  ListUserViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-11.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import SwiftMessages

final class ListUserViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    let logger = Logger(subsystem: "ListUserViewController", category: "ViewController")
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ListUserViewModel!
    
    private(set) lazy var addBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .add,
        target: self,
        action: #selector(ListUserViewController.addBarButtonItemPressed(_:))
    )

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        return tableView
    }()
        
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ListUserViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.kind.title
        view.backgroundColor = .systemBackground
        
        let rightBarButtonItem: UIBarButtonItem? = {
            // only setup bar button for `members` kind list
            switch self.viewModel.kind {
            case .members:
                // only setup bar button for myList
                let isMyList: Bool = {
                    let managedObjectContext = self.context.managedObjectContext
                    guard let list = self.viewModel.kind.list.object(in: managedObjectContext) else { return false }
                    return list.owner.userIdentifer == viewModel.authContext.authenticationContext.userIdentifier
                }()
                return isMyList ? self.addBarButtonItem : nil
            case .subscribers:
                return nil
            }
        }()
        self.navigationItem.rightBarButtonItem = rightBarButtonItem

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.frame = view.bounds
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
        
        // setup batch fetch
        viewModel.listBatchFetchViewModel.setup(scrollView: tableView)
        viewModel.listBatchFetchViewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.stateMachine.enter(ListUserViewModel.State.Loading.self)
            }
            .store(in: &disposeBag)
        
        viewModel.listMembershipViewModel.delegate = self
    }
 
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

extension ListUserViewController {
    
    @objc private func addBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
                
        let list = viewModel.kind.list
        let addListMemberViewModel = AddListMemberViewModel(context: context, authContext: authContext, list: list)
        addListMemberViewModel.listMembershipViewModelDelegate = self
        
        coordinator.present(
            scene: .addListMember(viewModel: addListMemberViewModel),
            from: self,
            transition: .modal(animated: true, completion: nil)
        )
    }

}

// MARK: - UITableViewDelegate
extension ListUserViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:ListUserViewController.AutoGenerateTableViewDelegate

    // Generated using Sourcery
    // DO NOT EDIT
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        aspectTableView(tableView, didSelectRowAt: indexPath)
    }
    // sourcery:end
}

// MARK: - UserViewTableViewCellDelegate
extension ListUserViewController: UserViewTableViewCellDelegate { }

// MARK: - ListMembershipViewModelDelegate
extension ListUserViewController: ListMembershipViewModelDelegate {
    
    func listMembershipViewModel(_ viewModel: ListMembershipViewModel, didAddUser user: UserRecord) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        Task { @MainActor in
            await self.viewModel.update(user: user, action: .add)
        }   // end Task
    }
    
    func listMembershipViewModel(_ viewModel: ListMembershipViewModel, didRemoveUser user: UserRecord) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        Task { @MainActor in
            await self.viewModel.update(user: user, action: .remove)
        }   // end Task
    }
}

// MARK: - AuthContextProvider
extension ListUserViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}
