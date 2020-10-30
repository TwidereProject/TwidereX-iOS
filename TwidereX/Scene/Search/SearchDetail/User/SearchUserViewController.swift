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

final class SearchUserViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: SearchUserViewModel!
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UserBriefInfoTableViewCell.self, forCellReuseIdentifier: String(describing: UserBriefInfoTableViewCell.self))
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
        
        viewModel.context.authenticationService.currentActiveTwitterAutentication
            .assign(to: \.value, on: viewModel.currentTwitterAuthentication)
            .store(in: &disposeBag)
    }
    
}

// MARK: - UIScrollViewDelegate
extension SearchUserViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        let cells = tableView.visibleCells.compactMap { $0 as? TimelineBottomLoaderTableViewCell }
        guard let cell = cells.first else { return }
        
        if let tabBar = tabBarController?.tabBar, let window = view.window {
            let loaderCellFrameInWindow = tableView.convert(cell.frame, to: nil)
            let windowHeight = window.frame.height
            let loaderAppear = (loaderCellFrameInWindow.origin.y + 0.8 * cell.frame.height) < (windowHeight - tabBar.frame.height)
            if loaderAppear {
                viewModel.stateMachine.enter(SearchUserViewModel.State.Loading.self)
            }
        } else {
            viewModel.stateMachine.enter(SearchUserViewModel.State.Loading.self)
        }
    }
}

// MARK: - UITableViewDelegate
extension SearchUserViewController: UITableViewDelegate {
    
}
