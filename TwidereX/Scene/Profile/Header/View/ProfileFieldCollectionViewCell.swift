//
//  ProfileFieldCollectionViewCell.swift
//  ProfileFieldCollectionViewCell
//
//  Created by Cirno MainasuK on 2021-9-10.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import MetaTextKit
import Meta

protocol ProfileFieldCollectionViewCellDelegate: AnyObject {
    func profileFieldCollectionViewCell(_ cell: ProfileFieldCollectionViewCell, profileFieldContentView: ProfileFieldContentView, metaLabel: MetaLabel, didSelectMeta meta: Meta)
}

final class ProfileFieldCollectionViewCell: UICollectionViewListCell {
    
    weak var delegate: ProfileFieldCollectionViewCellDelegate?
    
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
        
        guard let contentView = self.contentView as? ProfileFieldContentView else {
            assertionFailure()
            return
        }
        contentView.delegate = self
    }
    
}

// MARK: - ProfileFieldContentViewDelegate
extension ProfileFieldCollectionViewCell: ProfileFieldContentViewDelegate {
    func profileFieldContentView(_ contentView: ProfileFieldContentView, metaLabel: MetaLabel, didSelectMeta meta: Meta) {
        delegate?.profileFieldCollectionViewCell(self, profileFieldContentView: contentView, metaLabel: metaLabel, didSelectMeta: meta)
    }
}
 
