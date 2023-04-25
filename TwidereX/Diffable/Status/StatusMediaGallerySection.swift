//
//  StatusMediaGallerySection.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import SwiftUI
import CoreData
import CoreDataStack

enum StatusMediaGallerySection: Int, Hashable {
    case main
    case footer
}

extension StatusMediaGallerySection {
        
    struct Configuration {
        weak var statusMediaGalleryCollectionCellDelegate: StatusMediaGalleryCollectionCellDelegate?
    }
    
    static func diffableDataSource(
        collectionView: UICollectionView,
        context: AppContext,
        configuration: Configuration
    ) -> UICollectionViewDiffableDataSource<StatusSection, StatusItem> {
        
        let statusRecordCell = UICollectionView.CellRegistration<StatusMediaGalleryCollectionCell, StatusRecord> { cell, indexPath, record in
            context.managedObjectContext.performAndWait {
                guard let status = record.object(in: context.managedObjectContext) else {
                    assertionFailure()
                    return
                }
                let items = MediaView.ViewModel.viewModels(from: status)
                let viewModel = MediaStackContainerView.ViewModel(items: items)
                cell.contentConfiguration = UIHostingConfiguration {
                    MediaStackContainerView(viewModel: viewModel)
                }
                .margins(.vertical, 0)  // remove vertical margins
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

//    static func configure(
//        collectionView: UICollectionView,
//        cell: StatusMediaGalleryCollectionCell,
//        status: StatusObject,
//        configuration: Configuration
//    ) {
//        cell.configure(status: status)
//        cell.delegate = configuration.statusMediaGalleryCollectionCellDelegate
//    }
    
}
