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
import TwidereUI

extension SearchUserViewModel {
    @MainActor func setupDiffableDataSource(
        tableView: UITableView,
        userViewTableViewCellDelegate: UserViewTableViewCellDelegate
    ) {
        diffableDataSource = UserSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: UserSection.Configuration(
                userViewTableViewCellDelegate: userViewTableViewCellDelegate,
                listMembershipViewModel: listMembershipViewModel
            )
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems([], toSection: .main)
        diffableDataSource?.apply(snapshot)
        
        userRecordFetchedResultController.$records
            .receive(on: DispatchQueue.global())
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
                        let newItems: [UserItem] = records.map { record in
                            switch self.kind {
                            case .friendship:
                                return .user(record: record, style: .relationship)
                            case .listMember:
                                return .user(record: record, style: .addListMember)
                            }   // end switch
                        }
                        snapshot.appendItems(newItems, toSection: .main)
                        return snapshot
                    }()
                    
                    if let currentState = self.stateMachine.currentState {
                        switch currentState {
                        case is State.Idle, is State.Loading, is State.Fail:
                            guard !self.searchText.isEmpty else { break }
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
    }   // end func setupDiffableDataSource
    
    @MainActor private func updateDataSource(
        snapshot: NSDiffableDataSourceSnapshot<UserSection, UserItem>,
        animatingDifferences: Bool
    ) async {
        await diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }

}
