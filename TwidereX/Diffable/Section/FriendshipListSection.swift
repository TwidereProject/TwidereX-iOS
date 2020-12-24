//
//  FriendshipListSection.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import CoreData
import CoreDataStack

enum FriendshipListSection: Equatable, Hashable {
    case main
}

extension MediaSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        apiService: APIService,
        managedObjectContext: NSManagedObjectContext
    ) -> UITableViewDiffableDataSource<FriendshipListSection, Item> {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .twitterUser(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: FriendshipTableViewCell.self), for: indexPath) as! FriendshipTableViewCell
                managedObjectContext.performAndWait {
                    let twitterUser = managedObjectContext.object(with: objectID) as! TwitterUser
                    MediaSection.configure(cell: cell, twitterUser: twitterUser, apiService: apiService)
                }
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.isHidden = false
                cell.activityIndicatorView.startAnimating()
                cell.loadMoreButton.isHidden = true
                return cell
            default:
                assertionFailure()
                return nil
            }
        }
    }
}

extension MediaSection {
    static func configure(cell: FriendshipTableViewCell, twitterUser: TwitterUser, apiService: APIService) {
        cell.userBriefInfoView.configure(avatarImageURL: twitterUser.avatarImageURL(), verified: twitterUser.verified)
        cell.userBriefInfoView.lockImageView.isHidden = !twitterUser.protected
        cell.userBriefInfoView.nameLabel.text = twitterUser.name
        cell.userBriefInfoView.usernameLabel.text = "@" + twitterUser.username
        
        let followersCount = twitterUser.metrics?.followersCount.flatMap { String($0.intValue) } ?? "-"
        cell.userBriefInfoView.detailLabel.text = "\(L10n.Common.Controls.Friendship.followers.capitalized): \(followersCount)"
        
        if #available(iOS 14.0, *) {
            let menuItems = [
                UIDeferredMenuElement { completion in
                    let discoverabilityTitle = ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        let followAction = UIAction(title: "Follow", image: nil, identifier: nil, discoverabilityTitle: discoverabilityTitle, attributes: [], state: .off) { _ in
                            
                        }
                        let menu = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: [followAction])
                        completion([menu])
                    }
                }
            ]
            cell.userBriefInfoView.menuButton.menu = UIMenu(title: "", children: menuItems)
            cell.userBriefInfoView.menuButton.showsMenuAsPrimaryAction = true
        } else {
            // Fallback on earlier versions
        }
    }
}
