//
//  StatusSection.swift
//  StatusSection
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import CoreData
import CoreDataStack

enum StatusSection: Hashable {
    case main
}

extension StatusSection {
    static func diffableDataSource(
        collectionView: UICollectionView,
        context: AppContext
    ) -> UICollectionViewDiffableDataSource<StatusSection, StatusItem> {
        let cellRegistrationForTwitterStatus = UICollectionView.CellRegistration<StatusCollectionViewCell, TwitterStatus> { cell, indexPath, status in
            status.publisher(for: \.id).sink { id in
                let metaContent = PlaintextMetaContent(string: id)
                cell.statusView.authorNameLabel.configure(content: metaContent)
            }
            .store(in: &cell.disposeBag)
        }

        return UICollectionViewDiffableDataSource<StatusSection, StatusItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            // configure cell with item
            switch item {
            case .homeTimelineFeed(let objectID):
                guard let feed = try? context.managedObjectContext.existingObject(with: objectID) as? Feed,
                      let status = feed.twitterStatus
                else {
                    assertionFailure()
                    return UICollectionViewCell()
                }
                return collectionView.dequeueConfiguredReusableCell(
                    using: cellRegistrationForTwitterStatus,
                    for: indexPath,
                    item: status
                )
                
            case .twitterStatus(let objectID):
                guard let status = try? context.managedObjectContext.existingObject(with: objectID) as? TwitterStatus
                else {
                    assertionFailure()
                    return UICollectionViewCell()
                }
                return collectionView.dequeueConfiguredReusableCell(
                    using: cellRegistrationForTwitterStatus,
                    for: indexPath,
                    item: status
                )
            }
        }
    }
}

