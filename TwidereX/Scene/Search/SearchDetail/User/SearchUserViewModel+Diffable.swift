//
//  SearchUserViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import CoreData
import CoreDataStack
import AlamofireImage

extension SearchUserViewModel {
    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .user(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserBriefInfoTableViewCell.self), for: indexPath) as! UserBriefInfoTableViewCell
                let requestTwitterUserID = self.context.authenticationService.currentTwitterUser.value?.id
                
                // configure cell
                let managedObjectContext = self.fetchedResultsController.managedObjectContext
                managedObjectContext.performAndWait {
                    let twitterUser = managedObjectContext.object(with: objectID) as! TwitterUser
                    SearchUserViewModel.configure(cell: cell, twitterUser: twitterUser, requestTwitterUserID: requestTwitterUserID)
                    SearchUserViewModel.internalConfigure(cell: cell, twitterUser: twitterUser, requestTwitterUserID: requestTwitterUserID)
                }
                cell.delegate = self.userBriefInfoTableViewCellDelegate
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.isHidden = false
                cell.activityIndicatorView.startAnimating()
                cell.loadMoreButton.isHidden = true
                return cell
            }
        }
    }
}

extension SearchUserViewModel {
    
    static func configure(cell: UserBriefInfoTableViewCell, twitterUser: TwitterUser, requestTwitterUserID: TwitterUser.ID?) {
        // set avatar
        if let avatarImageURL = twitterUser.avatarImageURL() {
            let placeholderImage = UIImage
                .placeholder(size: UserBriefInfoView.avatarImageViewSize, color: .systemFill)
                .af.imageRoundedIntoCircle()
            let filter = ScaledToSizeCircleFilter(size: TimelinePostView.avatarImageViewSize)
            cell.userBriefInfoView.avatarImageView.af.setImage(
                withURL: avatarImageURL,
                placeholderImage: placeholderImage,
                filter: filter,
                imageTransition: .crossDissolve(0.2)
            )
        } else {
            assertionFailure()
        }
        
        cell.userBriefInfoView.verifiedBadgeImageView.isHidden = !twitterUser.verified
        cell.userBriefInfoView.lockImageView.isHidden = !twitterUser.protected
        
        // set name and username
        cell.userBriefInfoView.nameLabel.text = twitterUser.name
        cell.userBriefInfoView.usernameLabel.text = "@" + twitterUser.username
        
        // set detail
        let followersCount = twitterUser.metrics?.followersCount.flatMap { "\($0)" } ?? "-"
        cell.userBriefInfoView.detailLabel.text = "Followers: \(followersCount)"
        
        
        if let requestTwitterUserID = requestTwitterUserID {
            cell.userBriefInfoView.followActionButton.isHidden = twitterUser.id == requestTwitterUserID
            let isPending = (twitterUser.followRequestSentFrom ?? Set()).contains(where: { $0.id == requestTwitterUserID })
            let isFollowing = (twitterUser.followingFrom ?? Set()).contains(where: { $0.id == requestTwitterUserID })
            cell.userBriefInfoView.followActionButton.style = isPending ? .pending : (isFollowing ? .following : .follow)
        } else {
            assertionFailure()
        }
    }
    
    private static func internalConfigure(cell: UserBriefInfoTableViewCell, twitterUser: TwitterUser, requestTwitterUserID: TwitterUser.ID?) {
        ManagedObjectObserver.observe(object: twitterUser)
            .sink { completion in
                
            } receiveValue: { change in
                guard let changeType = change.changeType else { return }
                switch changeType {
                case .update:
                    configure(cell: cell, twitterUser: twitterUser, requestTwitterUserID: requestTwitterUserID)
                case .delete:
                    break
                }
            }
            .store(in: &cell.disposeBag)

    }
}

extension SearchUserViewModel {
    enum Section: Hashable {
        case main
    }
    
    enum Item: Hashable {
        case user(twitterUserObjectID: NSManagedObjectID)
        case bottomLoader
        
        static func == (lhs: SearchUserViewModel.Item, rhs: SearchUserViewModel.Item) -> Bool {
            switch (lhs, rhs) {
            case (.user(let objectIDLeft), .user(let objectIDRight)):
                return objectIDLeft == objectIDRight
            case (.bottomLoader, bottomLoader):
                return true
            default:
                return false
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .user(let objectID):
                hasher.combine(objectID)
            case .bottomLoader:
                hasher.combine(String(describing: self))
            }
        }
    }
}
