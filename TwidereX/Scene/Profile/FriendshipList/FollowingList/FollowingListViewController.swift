//
//  FollowingListViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import GameplayKit
import TwidereAsset
import TwidereLocalization

final class FollowingListViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "FollowingListViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: FriendshipListViewModel!
    
    let emptyStateView = EmptyStateView()
    
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

extension FollowingListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Following.title
        view.backgroundColor = .systemBackground
        
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        emptyStateView.isHidden = true
        
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
        
        viewModel.$isPermissionDenied
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPermissionDenied in
                guard let self = self else { return }
                self.emptyStateView.iconImageView.image = Asset.Human.eyeSlashLarge.image.withRenderingMode(.alwaysTemplate)
                self.emptyStateView.titleLabel.text = L10n.Common.Alerts.PermissionDeniedNotAuthorized.title
                self.emptyStateView.messageLabel.text = L10n.Common.Alerts.PermissionDeniedNotAuthorized.message
                self.emptyStateView.isHidden = !isPermissionDenied
            }
            .store(in: &disposeBag)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

// MARK: - UITableViewDelegate
extension FollowingListViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:FollowingListViewController.AutoGenerateTableViewDelegate

    // Generated using Sourcery
    // DO NOT EDIT
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        aspectTableView(tableView, didSelectRowAt: indexPath)
    }

    // sourcery:end
}
