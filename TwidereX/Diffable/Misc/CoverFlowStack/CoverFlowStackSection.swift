//
//  CoverFlowStackSection.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereCore

enum CoverFlowStackSection: Hashable {
    case main
}

extension CoverFlowStackSection {
    struct Configuration {
        
    }
    
    static func diffableDataSource(
        collectionView: UICollectionView,
        configuration: Configuration
    ) -> UICollectionViewDiffableDataSource<CoverFlowStackSection, CoverFlowStackItem> {
        
        let mediaCell = UICollectionView.CellRegistration<CoverFlowStackMediaCollectionCell, MediaView.ViewModel> { cell, indexPath, configuration in
            cell.configure(configuration: configuration)
        }
        
        return UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .media(let configuration):
                return collectionView.dequeueConfiguredReusableCell(using: mediaCell, for: indexPath, item: configuration)
            }
        }
    }
}
