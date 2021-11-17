//
//  StatusMediaGallerySection.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import CoreData
import CoreDataStack

enum StatusMediaGallerySection: Int, Hashable {
    case main
    case footer
}

extension StatusMediaGallerySection {
        
    struct Configuration {

    }
    
    static func diffableDataSource(
        collectionView: UICollectionView,
        context: AppContext,
        configuration: Configuration
    ) -> UICollectionViewDiffableDataSource<StatusMediaGallerySection, StatusItem> {
        
        let statusRecordCell = UICollectionView.CellRegistration<StatusMediaGalleryCollectionCell, StatusRecord> { cell, indexPath, record in
            context.managedObjectContext.performAndWait {
                guard let status = record.object(in: context.managedObjectContext) else {
                    assertionFailure()
                    return
                }
                configure(
                    collectionView: collectionView,
                    cell: cell,
                    status: status,
                    configuration: configuration
                )
            }
        }
        
        
        let activityIndicatorCell = UICollectionView.CellRegistration<ActivityIndicatorCollectionViewCell, String> { cell, IndexPath, _ in
            cell.activityIndicatorView.startAnimating()
        }
        
        return UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .status(let record):
                return collectionView.dequeueConfiguredReusableCell(using: statusRecordCell, for: indexPath, item: record)
            case .bottomLoader:
                return collectionView.dequeueConfiguredReusableCell(using: activityIndicatorCell, for: indexPath, item: String(describing: StatusItem.bottomLoader.self))
            default:
                assertionFailure()
                return UICollectionViewCell()
            }
        }
    }

}

extension StatusMediaGallerySection {

    static func configure(
        collectionView: UICollectionView,
        cell: StatusMediaGalleryCollectionCell,
        status: StatusObject,
        configuration: Configuration
    ) {
        cell.configure(status: status)
    }
}
