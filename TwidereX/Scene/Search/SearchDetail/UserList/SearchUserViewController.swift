//
//  SearchUserViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import TwitterSDK

final class SearchUserViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: SearchUserViewModel!
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(SearchUserTableViewCell.self, forCellReuseIdentifier: String(describing: SearchUserTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension SearchUserViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        viewModel.searchUserTableViewCellDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

// MARK: - UIScrollViewDelegate
extension SearchUserViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScrollViewDidScroll(scrollView)
    }
}

// MARK: - UITableViewDelegate
extension SearchUserViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        guard case let .twitterUser(objectID) = item else { return }
        let twitterUser = viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! TwitterUser
        
        let profileViewModel = ProfileViewModel(context: context, twitterUser: twitterUser)
        navigationController?.delegate = nil
        coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
    }
    
}

// MARK: - UserBriefInfoTableViewCellDelegate
extension SearchUserViewController: SearchUserTableViewCellDelegate { }

// MARK: - LoadMoreConfigurableTableViewContainer
extension SearchUserViewController: LoadMoreConfigurableTableViewContainer {
    typealias BottomLoaderTableViewCell = TimelineBottomLoaderTableViewCell
    typealias LoadingState = SearchUserViewModel.State.Loading
    var loadMoreConfigurableTableView: UITableView { return tableView }
    var loadMoreConfigurableStateMachine: GKStateMachine { return viewModel.stateMachine }
}
