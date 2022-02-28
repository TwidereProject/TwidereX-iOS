//
//  DrawerSidebarViewModel+Diffable.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-2.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereAsset

extension DrawerSidebarViewModel {
    func setupDiffableDataSource(
        sidebarCollectionView: UICollectionView,
        settingCollectionView: UICollectionView
    ) {
        // sidebar
        sidebarDiffableDataSource = setupDiffableDataSource(collectionView: sidebarCollectionView)
        var sidebarSnapshot = NSDiffableDataSourceSnapshot<SidebarSection, SidebarItem>()
        sidebarSnapshot.appendSections([.main])
        sidebarDiffableDataSource?.applySnapshotUsingReloadData(sidebarSnapshot)
        
        context.authenticationService.$activeAuthenticationContext
            .sink { [weak self] authenticationContext in
                guard let self = self else { return }
                var snapshot = NSDiffableDataSourceSnapshot<SidebarSection, SidebarItem>()
                snapshot.appendSections([.main])
                switch authenticationContext {
                case .twitter:
                    break
                case .mastodon:
                    snapshot.appendItems([.local, .federated], toSection: .main)
                case .none:
                    break
                }
                self.sidebarDiffableDataSource?.applySnapshotUsingReloadData(snapshot)
            }
            .store(in: &disposeBag)
        
        // setting
        settingDiffableDataSource = setupDiffableDataSource(collectionView: settingCollectionView)
        var settingSnapshot = NSDiffableDataSourceSnapshot<SidebarSection, SidebarItem>()
        settingSnapshot.appendSections([.main])
        settingSnapshot.appendItems([.settings], toSection: .main)
        settingDiffableDataSource?.applySnapshotUsingReloadData(settingSnapshot)
    }
    
}

extension DrawerSidebarViewModel {
    
    func setupDiffableDataSource(
        collectionView: UICollectionView
    ) -> UICollectionViewDiffableDataSource<SidebarSection, SidebarItem> {
        let entryCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> { cell, indexPath, item in
            var contentConfiguration = cell.defaultContentConfiguration()
            // attribute
            contentConfiguration.image = item.image
            contentConfiguration.text = item.title
            
            // appearance
            let tintColor: UIColor = {
                switch item {
                case .settings:     return .secondaryLabel.withAlphaComponent(0.8)
                default:            return .secondaryLabel
                }
            }()
            contentConfiguration.imageProperties.tintColor = tintColor
            contentConfiguration.textProperties.color = tintColor
            let tintColorTransformer = UIConfigurationColorTransformer { [weak cell] _ in
                guard let state = cell?.configurationState else {
                    return .clear
                }
                if state.isSelected || state.isHighlighted {
                    return Asset.Colors.hightLight.color
                } else {
                    return tintColor
                }
            }
            contentConfiguration.imageProperties.tintColorTransformer = tintColorTransformer
            contentConfiguration.textProperties.colorTransformer = tintColorTransformer
            contentConfiguration.textProperties.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
            
            // margin
            contentConfiguration.directionalLayoutMargins.top = 16
            contentConfiguration.directionalLayoutMargins.bottom = 16
            
            cell.contentConfiguration = contentConfiguration
            
            // background
            var backgroundConfiguration: UIBackgroundConfiguration
            switch item {
            case .settings:
                backgroundConfiguration = UIBackgroundConfiguration.listAccompaniedSidebarCell()
                backgroundConfiguration.cornerRadius = 0
                backgroundConfiguration.backgroundInsets.leading = 0
                backgroundConfiguration.backgroundInsets.trailing = 0
            default:
                backgroundConfiguration = UIBackgroundConfiguration.listPlainCell()
                backgroundConfiguration.cornerRadius = 12
                backgroundConfiguration.backgroundInsets.leading = -8
                backgroundConfiguration.backgroundInsets.trailing = -8
            }
            backgroundConfiguration.backgroundColorTransformer = UIConfigurationColorTransformer { [weak cell] _ in
                guard let state = cell?.configurationState else {
                    return .clear
                }
                if state.isSelected || state.isHighlighted {
                    return Asset.Scene.Sidebar.entryCellHighlightedBackground.color
                } else {
                    return .clear
                }
            }
            cell.backgroundConfiguration = backgroundConfiguration
        }
        return UICollectionViewDiffableDataSource(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(
                using: entryCellRegistration,
                for: indexPath,
                item: item
            )
        }
    }
}
