//
//  DrawerSidebarViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-9.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine

final class DrawerSidebarViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()

    let headerView = DrawerSidebarHeaderView()    
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(DrawerSidebarEntryTableViewCell.self, forCellReuseIdentifier: String(describing: DrawerSidebarEntryTableViewCell.self))
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        return tableView
    }()
}

extension DrawerSidebarViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
    }
    
}
