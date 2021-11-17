//
//  ComposeContentViewController.swift
//  
//
//  Created by MainasuK on 2021/11/17.
//

import UIKit
import Combine

public final class ComposeContentViewController: UIViewController {
    
    public var viewModel: ComposeContentViewModel!
        
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
    
}

extension ComposeContentViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
}
