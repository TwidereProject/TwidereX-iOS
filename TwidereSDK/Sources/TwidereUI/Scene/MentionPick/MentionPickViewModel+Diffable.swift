//
//  MentionPickerViewModel+Diffable.swift
//  
//
//  Created by MainasuK on 2021-11-25.
//

import UIKit
import CoreData
import MetaTextKit

extension MentionPickViewModel {
    struct DataSourceConfiguration {
        weak var userTableViewCellDelegate: UserViewTableViewCellDelegate?
    }
    
    func setupDiffableDataSource(
        for tableView: UITableView,
        configuration: DataSourceConfiguration
    ) {
        tableView.register(UserMentionPickStyleTableViewCell.self, forCellReuseIdentifier: String(describing: UserMentionPickStyleTableViewCell.self))
        
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserMentionPickStyleTableViewCell.self), for: indexPath) as! UserMentionPickStyleTableViewCell
            MentionPickViewModel.configure(
                cell: cell,
                item: item,
                configuration: configuration
            )
            return cell
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.primary])
        snapshot.appendItems([primaryItem], toSection: .primary)
        if !secondaryItems.isEmpty {
            snapshot.appendSections([.secondary])
            snapshot.appendItems(secondaryItems, toSection: .secondary)
        }
        diffableDataSource?.apply(snapshot)
    }
}

extension MentionPickViewModel {
    
    // FIXME: use UserRecord bind view
    static func configure(
        cell: UserMentionPickStyleTableViewCell,
        item: Item,
        configuration: DataSourceConfiguration
    ) {
        switch item {
        case .twitterUser(let username, let attribute):
            cell.userView.viewModel.platform = .twitter
            cell.userView.viewModel.avatarImageURL = attribute.avatarImageURL
            cell.userView.viewModel.name = attribute.name.flatMap { PlaintextMetaContent(string: $0) }
            cell.userView.viewModel.username = "@" + username
            
            cell.userView.activityIndicatorView.isHidden = attribute.state == .finish
            cell.userView.checkmarkButton.isHidden = attribute.state == .loading

            if attribute.selected {
                cell.userView.checkmarkButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            } else {
                cell.userView.checkmarkButton.setImage(UIImage(systemName: "circle"), for: .normal)
            }
            cell.selectionStyle = attribute.disabled ? .none : .default
            cell.userView.checkmarkButton.tintColor = attribute.disabled ? .systemGray : (attribute.selected ? Asset.Colors.hightLight.color : .systemGray)
        }   // end switch
    }
    
}


