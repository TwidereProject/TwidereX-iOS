//
//  StatusThreadViewController.swift
//  StatusThreadViewController
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

final class StatusThreadViewController: UIViewController, NeedsDependency {

    let logger = Logger(subsystem: "StatusThreadViewController", category: "UI")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var viewModel: StatusThreadViewModel!
    
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(StatusThreadRootTableViewCell.self, forCellReuseIdentifier: String(describing: StatusThreadRootTableViewCell.self))
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorInsetReference = .fromCellEdges
        tableView.backgroundColor = .systemBackground
        return tableView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension StatusThreadViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            statusTableViewCellDelegate: self,
            statusThreadRootTableViewCellDelegate: self
        )
    }
    
}

// MARK: - StatusTableViewCellDelegate
extension StatusThreadViewController: StatusTableViewCellDelegate {
    func statusTableViewCell(_ cell: StatusTableViewCell, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
        // TODO:
    }
}

// MARK: - StatusThreadRootTableViewCellDelegate
extension StatusThreadViewController: StatusThreadRootTableViewCellDelegate {
    func statusThreadRootTableViewCell(_ cell: StatusThreadRootTableViewCell, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
        // TODO:
    }
    

}
