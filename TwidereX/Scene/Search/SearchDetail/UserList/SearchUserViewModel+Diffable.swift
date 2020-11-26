//
//  SearchUserViewModel+Diffable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import CoreData
import CoreDataStack
import AlamofireImage
import Kingfisher

extension SearchUserViewModel {
    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .twitterUser(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserBriefInfoTableViewCell.self), for: indexPath) as! UserBriefInfoTableViewCell
                let requestTwitterUserID = self.context.authenticationService.activeTwitterAuthenticationBox.value?.twitterUserID
                
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
            default:
                assertionFailure()
                return nil
            }
        }
    }
}

extension SearchUserViewModel {
    
    static func configure(cell: UserBriefInfoTableViewCell, twitterUser: TwitterUser, requestTwitterUserID: TwitterUser.ID?) {
        // set avatar
        if let avatarImageURL = twitterUser.avatarImageURL() {
            SearchUserViewModel.configure(avatarImageView: cell.userBriefInfoView.avatarImageView, avatarImageURL: avatarImageURL)
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
    
    static func configure(avatarImageView: UIImageView, avatarImageURL: URL) {
        let placeholderImage = UIImage
            .placeholder(size: UserBriefInfoView.avatarImageViewSize, color: .systemFill)
            .af.imageRoundedIntoCircle()
        
        if avatarImageURL.pathExtension == "gif" {
            avatarImageView.kf.setImage(
                with: avatarImageURL,
                placeholder: placeholderImage,
                options: [
                    .processor(
                        CroppingImageProcessor(size: UserBriefInfoView.avatarImageViewSize, anchor: CGPoint(x: 0.5, y: 0.5)) |>
                        RoundCornerImageProcessor(cornerRadius: 0.5 * UserBriefInfoView.avatarImageViewSize.width)
                    ),
                    .transition(.fade(0.2))
                ]
            )
        } else {
            let filter = ScaledToSizeCircleFilter(size: UserBriefInfoView.avatarImageViewSize)
            avatarImageView.af.setImage(
                withURL: avatarImageURL,
                placeholderImage: placeholderImage,
                filter: filter,
                imageTransition: .crossDissolve(0.2)
            )
        }
    }
    
}


// MARK: - NSFetchedResultsControllerDelegate
extension SearchUserViewModel: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let indexes = searchTwitterUserIDs.value
        let twitterUsers = fetchedResultsController.fetchedObjects ?? []
        guard twitterUsers.count == indexes.count else { return }
        
        let items: [Item] = twitterUsers
            .compactMap { twitterUser in
                indexes.firstIndex(of: twitterUser.id).map { index in (index, twitterUser) }
            }
            .sorted { $0.0 < $1.0 }
            .map { Item.twitterUser(objectID: $0.1.objectID) }
        self.items.value = items
    }
}
