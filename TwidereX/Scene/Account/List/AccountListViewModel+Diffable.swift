//
//  AccountListViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-11.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreDataStack
import AlamofireImage

extension AccountListViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView
    ) {
        diffableDataSource = UserSection.diffableDataSource(
            tableView: tableView,
            context: context
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
        
        context.authenticationService.authenticationIndexes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authenticationIndexes in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
                snapshot.appendSections([.main])
                let items = authenticationIndexes.map { authenticationIndex -> UserItem in
                    let record = ManagedObjectRecord<AuthenticationIndex>(objectID: authenticationIndex.objectID)
                    return UserItem.authenticationIndex(record: record)
                }
                snapshot.appendItems(items, toSection: .main)
                diffableDataSource.apply(snapshot)
            }
            .store(in: &disposeBag)
    }
    
//    static func configure(cell: AccountListTableViewCell, twitterUser: TwitterUser, accountListViewControllerDelegate: AccountListViewControllerDelegate?) {
//        // set avatar
//        let avatarImageURL = twitterUser.avatarImageURL()
//        let verified = twitterUser.verified
//        UserDefaults.shared
//            .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
//                cell.userBriefInfoView.configure(withConfigurationInput: AvatarConfigurableViewConfiguration.Input(avatarImageURL: avatarImageURL, verified: verified))
//            }
//            .store(in: &cell.observations)
//        
//        cell.userBriefInfoView.lockImageView.isHidden = !twitterUser.protected
//        
//        // set name and username
//        cell.userBriefInfoView.nameLabel.text = twitterUser.name
//        cell.userBriefInfoView.headerSecondaryLabel.text = ""
//        
//        cell.userBriefInfoView.detailLabel.text = "@" + twitterUser.username
//        
//        if let accountListViewControllerDelegate = accountListViewControllerDelegate {
//            if #available(iOS 14.0, *) {
//                let menuItems = [
//                    UIMenu(
//                        title: L10n.Scene.ManageAccounts.deleteAccount,
//                        options: .destructive,
//                        children: [
//                            UIAction(
//                                title: L10n.Common.Controls.Actions.remove,
//                                image: nil,
//                                attributes: .destructive,
//                                state: .off,
//                                handler: { [weak accountListViewControllerDelegate] _ in
//                                    accountListViewControllerDelegate?.signoutTwitterUser(id: twitterUser.id)
//                                }
//                            ),
//                            UIAction(
//                                title: L10n.Common.Controls.Actions.cancel,
//                                attributes: [],
//                                state: .off,
//                                handler: { _ in
//                                    // do nothing
//                                }
//                            )
//                        ]
//                    )
//                ]
//                cell.userBriefInfoView.menuButton.menu = UIMenu(title: "", children: menuItems)
//                cell.userBriefInfoView.menuButton.showsMenuAsPrimaryAction = true
//            } else {
//                // delegate handle the button
//            }
//        }
//    }

}
