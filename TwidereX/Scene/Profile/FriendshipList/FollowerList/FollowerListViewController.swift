//
//  FollowerList.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import Combine
import GameplayKit
import TwidereAsset
import TwidereLocalization
import TwidereUI

final class FollowerListViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "FollowerListViewController", category: "ViewController")

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: FriendshipListViewModel!
    let emptyStateViewModel = EmptyStateView.ViewModel()

    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
}

extension FollowerListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Followers.title
        view.backgroundColor = .systemBackground
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(tableView: tableView)
        viewModel.listBatchFetchViewModel.setup(scrollView: tableView)
        viewModel.listBatchFetchViewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard self.isDisplaying else { return }
                self.viewModel.stateMachine.enter(FriendshipListViewModel.State.Loading.self)
            }
            .store(in: &disposeBag)
        
        let emptyStateViewHostingController = UIHostingController(rootView: EmptyStateView(viewModel: emptyStateViewModel))
        addChild(emptyStateViewHostingController)
        emptyStateViewHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateViewHostingController.view)
        NSLayoutConstraint.activate([
            emptyStateViewHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateViewHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateViewHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateViewHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        emptyStateViewHostingController.view.isHidden = true
        
        viewModel.$isPermissionDenied
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPermissionDenied in
                guard let self = self else { return }
                self.emptyStateViewModel.emptyState = isPermissionDenied ? .unableToAccess : nil
                emptyStateViewHostingController.view.isHidden = !isPermissionDenied
            }
            .store(in: &disposeBag)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

// MARK: - AuthContextProvider
extension FollowerListViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - UITableViewDelegate
extension FollowerListViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:FollowerListViewController.AutoGenerateTableViewDelegate

    // Generated using Sourcery
    // DO NOT EDIT
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        aspectTableView(tableView, didSelectRowAt: indexPath)
    }

    // sourcery:end
}

