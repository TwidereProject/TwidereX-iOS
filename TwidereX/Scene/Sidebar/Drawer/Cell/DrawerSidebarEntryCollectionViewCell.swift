//
//  DrawerSidebarEntryCollectionViewCell.swift
//  TwidereX
//
//  Created by MainasuK on 2022-1-13.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import TwidereAsset

final class DrawerSidebarEntryCollectionViewCell: UICollectionViewListCell {
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        
//        var contentConfiguration = self.contentConfiguration?.updated(for: state)
        
        
        var backgroundConfiguration = UIBackgroundConfiguration.clear()
        backgroundConfiguration.cornerRadius = 12
        backgroundConfiguration.backgroundColor = state.isSelected || state.isHighlighted ? Asset.Scene.Sidebar.entryCellHighlightedBackground.color : .clear
        self.backgroundConfiguration = backgroundConfiguration
    }
}
