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
    func setupDiffableDataSource(
        tableView: UITableView,
        userTableViewCellDelegate: UserTableViewCellDelegate
    ) {
        diffableDataSource = UserSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: UserSection.Configuration(
                userTableViewCellDelegate: userTableViewCellDelegate
            )
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems([], toSection: .main)
        diffableDataSource?.apply(snapshot)
        
        userRecordFetchedResultController.records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let _ = self.diffableDataSource else { return }

                let recordsCount = records.count
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): incoming \(recordsCount) objects")
                Task {
                    let start = CACurrentMediaTime()
                    defer {
                        let end = CACurrentMediaTime()
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): cost \(end - start, format: .fixed(precision: 4))s to process \(recordsCount) feeds")
                    }
                    
                    var newSnapshot: NSDiffableDataSourceSnapshot<UserSection, UserItem> = {
                        var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
                        snapshot.appendSections([.main])
                        let newItems: [UserItem] = records.map {
                            .user(record: $0, style: .friendship)
                        }
                        snapshot.appendItems(newItems, toSection: .main)
                        return snapshot
                    }()
                    
                    if let currentState = self.stateMachine.currentState {
                        switch currentState {
                        case is State.Idle, is State.Loading, is State.Fail:
                            newSnapshot.appendItems([.bottomLoader], toSection: .main)
                        case is State.NoMore:
                            break
                        default:
                            break
                        }
                    }
                    
                    await self.updateDataSource(snapshot: newSnapshot, animatingDifferences: false)
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot")
                }
            }
            .store(in: &disposeBag)
        
//        UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
//            guard let self = self else { return nil }
//
//            switch item {
//            case .twitterUser(let objectID):
//                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchUserTableViewCell.self), for: indexPath) as! SearchUserTableViewCell
//                let requestTwitterUserID = self.context.authenticationService.activeTwitterAuthenticationBox.value?.twitterUserID
//
//                // configure cell
//                let managedObjectContext = self.fetchedResultsController.managedObjectContext
//                managedObjectContext.performAndWait {
//                    let twitterUser = managedObjectContext.object(with: objectID) as! TwitterUser
//                    SearchUserViewModel.configure(cell: cell, twitterUser: twitterUser, requestTwitterUserID: requestTwitterUserID)
//                    SearchUserViewModel.internalConfigure(cell: cell, twitterUser: twitterUser, requestTwitterUserID: requestTwitterUserID)
//                }
//                cell.delegate = self.searchUserTableViewCellDelegate
//                return cell
//            case .bottomLoader:
//                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
//                cell.activityIndicatorView.isHidden = false
//                cell.activityIndicatorView.startAnimating()
//                cell.loadMoreButton.isHidden = true
//                return cell
//            default:
//                assertionFailure()
//                return nil
//            }
//        }
    }   // end func setupDiffableDataSource
    
    @MainActor private func updateDataSource(
        snapshot: NSDiffableDataSourceSnapshot<UserSection, UserItem>,
        animatingDifferences: Bool
    ) async {
        await diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }

}

extension SearchUserViewModel {
    
//    static func configure(cell: SearchUserTableViewCell, twitterUser: TwitterUser, requestTwitterUserID: TwitterUser.ID?) {
//        // set avatar
//        let avatarImageURL = twitterUser.avatarImageURL()
//        let verified = twitterUser.verified
////        UserDefaults.shared
////            .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
////                cell.userBriefInfoView.configure(withConfigurationInput: AvatarConfigurableViewConfiguration.Input(avatarImageURL: avatarImageURL, verified: verified))
////            }
////            .store(in: &cell.observations)
//
////        cell.userBriefInfoView.lockImageView.isHidden = !twitterUser.protected
//
//        // set name and username
//        cell.userBriefInfoView.headlineLabel.text = twitterUser.name
//        cell.userBriefInfoView.secondaryHeadlineLabel.text = "@" + twitterUser.username
//
//        // set detail
//        let followersCount = 0
//        cell.userBriefInfoView.subheadlineLabel.text = "\(L10n.Common.Controls.Friendship.followers.capitalized): \(followersCount)"
//
//        if let requestTwitterUserID = requestTwitterUserID {
//            cell.userBriefInfoView.followActionButton.isHidden = twitterUser.id == requestTwitterUserID
//            let isPending = (twitterUser.followRequestSentFrom ?? Set()).contains(where: { $0.id == requestTwitterUserID })
//            let isFollowing = (twitterUser.followingBy ?? Set()).contains(where: { $0.id == requestTwitterUserID })
//            cell.userBriefInfoView.followActionButton.style = isPending ? .pending : (isFollowing ? .following : .follow)
//        } else {
//            assertionFailure()
//        }
//    }
    
//    private static func internalConfigure(cell: SearchUserTableViewCell, twitterUser: TwitterUser, requestTwitterUserID: TwitterUser.ID?) {
//        ManagedObjectObserver.observe(object: twitterUser)
//            .sink { completion in
//
//            } receiveValue: { change in
//                guard let changeType = change.changeType else { return }
//                switch changeType {
//                case .update:
//                    configure(cell: cell, twitterUser: twitterUser, requestTwitterUserID: requestTwitterUserID)
//                case .delete:
//                    break
//                }
//            }
//            .store(in: &cell.disposeBag)
//    }
    
}


//// MARK: - NSFetchedResultsControllerDelegate
//extension SearchUserViewModel: NSFetchedResultsControllerDelegate {
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
//        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        
//        let indexes = searchTwitterUserIDs.value
//        let twitterUsers = fetchedResultsController.fetchedObjects ?? []
//        guard twitterUsers.count == indexes.count else { return }
//        
//        let items: [Item] = twitterUsers
//            .compactMap { twitterUser in
//                indexes.firstIndex(of: twitterUser.id).map { index in (index, twitterUser) }
//            }
//            .sorted { $0.0 < $1.0 }
//            .map { Item.twitterUser(objectID: $0.1.objectID) }
//        self.items.value = items
//    }
//}
