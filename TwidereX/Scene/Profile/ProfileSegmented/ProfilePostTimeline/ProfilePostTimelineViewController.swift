//
//  ProfilePostTimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import UIKit
import Combine

final class ProfilePostTimelineViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ConversationPostTableViewCell.self, forCellReuseIdentifier: String(describing: ConversationPostTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
}

extension ProfilePostTimelineViewController {
    
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
        
        tableView.delegate = self
        // tableView.dataSource = viewModel        
    }
    
}

// MARK: - UITableViewDelegate
extension ProfilePostTimelineViewController: UITableViewDelegate {
    
}
