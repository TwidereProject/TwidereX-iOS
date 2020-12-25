//
//  FollowingListViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine
import GameplayKit

final class FollowingListViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: FollowingListViewModel!
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(FriendshipTableViewCell.self, forCellReuseIdentifier: String(describing: FriendshipTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
}

extension FollowingListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Following.title
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        tableView.backgroundColor = .systemBackground
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(for: tableView)
        viewModel.stateMachine.enter(FollowingListViewModel.State.Loading.self)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

// MARK: - UIScrollViewDelegate
extension FollowingListViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScrollViewDidScroll(scrollView)
    }
}

// MARK: - UITableViewDelegate
extension FollowingListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        handleTableView(tableView, didSelectRowAt: indexPath)
    }
}

// MARK: - LoadMoreConfigurableTableViewContainer
extension FollowingListViewController: LoadMoreConfigurableTableViewContainer {
    
    typealias BottomLoaderTableViewCell = TimelineBottomLoaderTableViewCell
    typealias LoadingState = FollowingListViewModel.State.Loading
    
    var loadMoreConfigurableTableView: UITableView { return tableView }
    var loadMoreConfigurableStateMachine: GKStateMachine { return viewModel.stateMachine }
    
}
