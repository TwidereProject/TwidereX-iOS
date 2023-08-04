//
//  MentionPickerViewModel+Diffable.swift
//  
//
//  Created by MainasuK on 2021-11-25.
//

import UIKit
import SwiftUI
import CoreData
import MetaTextKit

extension MentionPickViewModel {
    
    struct Configuration {
        weak var userViewTableViewCellDelegate: UserViewTableViewCellDelegate?
    }

    func setupDiffableDataSource(
        tableView: UITableView,
        context: AppContext,
        authContext: AuthContext,
        configuration: Configuration
    ) {
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: String(describing: UserTableViewCell.self))

        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserTableViewCell.self), for: indexPath) as! UserTableViewCell
            cell.userViewTableViewCellDelegate = configuration.userViewTableViewCellDelegate
    
            let viewModel = UserView.ViewModel(
                item: item,
                delegate: cell
            )
            cell.contentConfiguration = UIHostingConfiguration {
                UserView(viewModel: viewModel)
            }
            .margins(.vertical, 0)  // remove vertical margins
            switch item {
            case .twitterUser(_, let attribute):
                cell.selectionStyle = attribute.disabled ? .none : .default
            }

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
//    static func configure(
//        cell: UserMentionPickStyleTableViewCell,
//        item: Item,
//        configuration: DataSourceConfiguration
//    ) {
//        switch item {
//        case .twitterUser(let username, let attribute):
//            cell.userView.viewModel.platform = .twitter
//            cell.userView.viewModel.avatarImageURL = attribute.avatarImageURL
//            cell.userView.viewModel.name = attribute.name.flatMap { PlaintextMetaContent(string: $0) }
//            cell.userView.viewModel.username = "@" + username
//
//            cell.userView.activityIndicatorView.isHidden = attribute.state == .finish
//            cell.userView.checkmarkButton.isHidden = attribute.state == .loading
//
//            if attribute.selected {
//                cell.userView.checkmarkButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
//            } else {
//                cell.userView.checkmarkButton.setImage(UIImage(systemName: "circle"), for: .normal)
//            }
//            cell.selectionStyle = attribute.disabled ? .none : .default
//            cell.userView.checkmarkButton.tintColor = attribute.disabled ? .systemGray : (attribute.selected ? Asset.Colors.hightLight.color : .systemGray)
//        }   // end switch
//    }
    
}


