//
//  DrawerSidebarViewModel+Diffable.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-2.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

extension DrawerSidebarViewModel {
    func setupDiffableDataSource(
        sidebarTableView: UITableView,
        settingTableView: UITableView
    ) {
        sidebarDiffableDataSource = setupDiffableDataSource(tableView: sidebarTableView)
        settingDiffableDataSource = setupDiffableDataSource(tableView: settingTableView)
        
        
        var settingSnapshot = NSDiffableDataSourceSnapshot<SidebarSection, SidebarItem>()
        settingSnapshot.appendSections([.main])
        settingSnapshot.appendItems([.settings], toSection: .main)
        settingDiffableDataSource?.apply(settingSnapshot)
    }
    
    func setupDiffableDataSource(tableView: UITableView) -> UITableViewDiffableDataSource<SidebarSection, SidebarItem> {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: DrawerSidebarEntryTableViewCell.self), for: indexPath) as! DrawerSidebarEntryTableViewCell
            cell.entryView.iconImageView.image = item.image
            cell.entryView.iconImageView.tintColor = UIColor.label.withAlphaComponent(0.8)
            cell.entryView.titleLabel.text = item.title
            cell.entryView.titleLabel.textColor = UIColor.label.withAlphaComponent(0.8)
            return cell
        }
    }
    
}
