//
//  MentionPickViewController.swift
//  
//
//  Created by MainasuK on 2021-11-25.
//

import os.log
import UIKit
import Combine
import TwidereLocalization
import TwidereUI

protocol MentionPickViewControllerDelegate: AnyObject {
    func mentionPickViewController(_ controller: MentionPickViewController, itemPickDidChange items: [MentionPickViewModel.Item])
}

public final class MentionPickViewController: UIViewController {
    
    var viewModel: MentionPickViewModel!
    weak var delegate: MentionPickViewControllerDelegate?
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tableHeaderView = UITableView.groupedTableViewPaddingHeaderView
        return tableView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension MentionPickViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Compose.replyingTo
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(MentionPickViewController.closeBarButtonItemPressed(_:)))
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            for: tableView,
            configuration: MentionPickViewModel.DataSourceConfiguration(
                userTableViewCellDelegate: self
            )
        )
    }
    
}

extension MentionPickViewController {
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate
extension MentionPickViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .twitterUser(_, let attribute):
            guard !attribute.disabled else { return }
            attribute.selected.toggle()
            var snapshot = diffableDataSource.snapshot()
            snapshot.reloadItems([item])
            diffableDataSource.apply(snapshot)
        }

        delegate?.mentionPickViewController(self, itemPickDidChange: viewModel.secondaryItems)
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < MentionPickViewModel.Section.allCases.count else { return nil }
        switch MentionPickViewModel.Section.allCases[section] {
        case .primary:
            return nil
        case .secondary:
            let header = TableViewSectionTextHeaderView()
            header.label.text = L10n.Scene.Compose.othersInThisConversation
            return header
        }
    }
    
}

// MARK: - UserTableViewCellDelegate
extension MentionPickViewController: UserViewTableViewCellDelegate {
    public func tableViewCell(_ cell: UITableViewCell, userView: UserView, menuActionDidPressed action: UserView.MenuAction, menuButton button: UIButton) {
        // do nothing
    }
    
    public func tableViewCell(_ cell: UITableViewCell, userView: UserView, friendshipButtonDidPressed button: UIButton) {
        // do nothing
    }
    
    public func tableViewCell(_ cell: UITableViewCell, userView: UserView, membershipButtonDidPressed button: UIButton) {
        // do nothing
    }
}
