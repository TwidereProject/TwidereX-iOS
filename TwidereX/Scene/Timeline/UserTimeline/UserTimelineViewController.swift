//
//  UserTimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import UIKit
import Combine

final class UserTimelineViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: UserTimelineViewModel!
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(TimelinePostTableViewCell.self, forCellReuseIdentifier: String(describing: TimelinePostTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
}

extension UserTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.backgroundColor = .systemBackground
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        viewModel.setupDiffableDataSource(for: tableView)
        tableView.delegate = self
        tableView.dataSource = viewModel.diffableDataSource
    }
    
}

// MARK: - UITableViewDelegate
extension UserTimelineViewController: UITableViewDelegate {
    
}
