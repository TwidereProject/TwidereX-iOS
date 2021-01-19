//
//  TwitterAuthenticationOptionViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit

final class TwitterAuthenticationOptionViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: TwitterAuthenticationOptionViewModel!
    
    let signInBarButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.signIn, style: .done, target: nil, action: nil)
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(ListTextFieldTableViewCell.self, forCellReuseIdentifier: String(describing: ListTextFieldTableViewCell.self))
        return tableView
    }()

}

extension TwitterAuthenticationOptionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem.cancelBarButtonItem(target: self, action: #selector(TwitterAuthenticationOptionViewController.cancelBarButtonItemPressed(_:)))
        navigationItem.rightBarButtonItem = signInBarButtonItem
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        tableView.dataSource = viewModel

        signInBarButtonItem.target = self
        signInBarButtonItem.action = #selector(TwitterAuthenticationOptionViewController.signInBarButtonItemPressed(_:))
    }

}

extension TwitterAuthenticationOptionViewController {

    @objc private func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        dismiss(animated: true, completion: nil)
    }
    
    @objc private func signInBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        
    }
    
}

// MARK: - UITableViewDelegate
extension TwitterAuthenticationOptionViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < viewModel.sections.count else { return nil }
        let section = viewModel.sections[section]
        
        guard let header = section.header else { return nil }
        let headerView = TableViewSectionTextHeaderView()
        headerView.headerLabel.text = header
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section < viewModel.sections.count else { return nil }
        let section = viewModel.sections[section]
        
        guard let footer = section.footer else { return nil }
        let footerView = TableViewSectionTextHeaderView()
        footerView.headerLabel.text = footer
        footerView.headerLabel.font = .preferredFont(forTextStyle: .footnote)
        return footerView
    }
    
}
