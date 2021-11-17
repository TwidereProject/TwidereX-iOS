//
//  ProfileFieldCollectionViewCell.swift
//  ProfileFieldCollectionViewCell
//
//  Created by Cirno MainasuK on 2021-9-10.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

final class ProfileFieldCollectionViewCell: UICollectionViewListCell {
    
    var item: ProfileFieldListView.Item?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileFieldCollectionViewCell {
    
    private func _init() {
        
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        var newConfiguration = ProfileFieldContentView.ContentConfiguration().updated(for: state)
        newConfiguration.item = item
        contentConfiguration = newConfiguration
                
        var newBackgroundConfiguration = UIBackgroundConfiguration.listPlainCell()
        // disable selection
        newBackgroundConfiguration.backgroundColor = .clear
        backgroundConfiguration = newBackgroundConfiguration
    }
    
}
