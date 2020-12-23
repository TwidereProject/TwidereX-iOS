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
        managedObjectContext: NSManagedObjectContext,
        friendshipTableViewCellDelegate: FriendshipTableViewCellDelegate
    ) -> UITableViewDiffableDataSource<FriendshipListSection, Item> {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .twitterUser(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: FriendshipTableViewCell.self), for: indexPath) as! FriendshipTableViewCell
                managedObjectContext.performAndWait {
                    let twitterUser = managedObjectContext.object(with: objectID) as! TwitterUser
                    MediaSection.configure(cell: cell, twitterUser: twitterUser)
                }
                cell.delegate = friendshipTableViewCellDelegate
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
    static func configure(cell: FriendshipTableViewCell, twitterUser: TwitterUser) {
        cell.userBriefInfoView.configure(avatarImageURL: twitterUser.avatarImageURL(), verified: twitterUser.verified)
        cell.userBriefInfoView.lockImageView.isHidden = !twitterUser.protected
        cell.userBriefInfoView.nameLabel.text = twitterUser.name
        cell.userBriefInfoView.usernameLabel.text = "@" + twitterUser.username
        
        let followersCount = twitterUser.metrics?.followersCount.flatMap { String($0.intValue) } ?? "-"
        cell.userBriefInfoView.detailLabel.text = "\(L10n.Common.Controls.Friendship.followers.capitalized): \(followersCount)"
    }
}
