//
//  FollowerList.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import GameplayKit

final class FollowerListViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: FriendshipListViewModel!
    
    let emptyStateView = EmptyStateView()
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(FriendshipTableViewCell.self, forCellReuseIdentifier: String(describing: FriendshipTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
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
        viewModel.setupDiffableDataSource(for: tableView)
        viewModel.stateMachine.enter(FriendshipListViewModel.State.Loading.self)
        
        viewModel.isPermissionDenied
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

// MARK: - UIScrollViewDelegate
extension FollowerListViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScrollViewDidScroll(scrollView)
    }
}

// MARK: - UITableViewDelegate
extension FollowerListViewController: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        handleTableView(tableView, didSelectRowAt: indexPath)
//    }
}

// MARK: - LoadMoreConfigurableTableViewContainer
extension FollowerListViewController: LoadMoreConfigurableTableViewContainer {
    
    typealias BottomLoaderTableViewCell = TimelineBottomLoaderTableViewCell
    typealias LoadingState = FriendshipListViewModel.State.Loading
    
    var loadMoreConfigurableTableView: UITableView { return tableView }
    var loadMoreConfigurableStateMachine: GKStateMachine { return viewModel.stateMachine }
    
}
