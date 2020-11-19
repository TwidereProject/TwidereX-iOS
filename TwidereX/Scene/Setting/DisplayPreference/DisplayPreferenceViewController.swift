//
//  DisplayPreferenceViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-17.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

final class DisplayPreferenceViewController: UIViewController, NeedsDependency {

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    let viewModel = DisplayPreferenceViewModel()

    private(set) lazy var tableView: UITableView = {
        let tableView = ControlContainableTableView(frame: .zero, style: .grouped)
        tableView.register(TimelinePostTableViewCell.self, forCellReuseIdentifier: String(describing: TimelinePostTableViewCell.self))
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: String(describing: SwitchTableViewCell.self))
        tableView.register(SlideTableViewCell.self, forCellReuseIdentifier: String(describing: SlideTableViewCell.self))
        
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 16))
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()
        
}

extension DisplayPreferenceViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Display"
        parent?.title = "Display"
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = viewModel
    }
    
}

// MARK: - UITableViewDelegate
extension DisplayPreferenceViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionData = viewModel.sections[section]
        let header = sectionData.header
        let headerView = TableViewSectionTextHeaderView()
        headerView.headerLabel.text = header
        return headerView
    }
    
}
