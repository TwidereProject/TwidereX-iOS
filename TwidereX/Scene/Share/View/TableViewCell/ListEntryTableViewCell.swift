//
//  ListEntryTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class ListEntryTableViewCell: ListTableViewCell {
    
    override func _init() {
        super._init()
        
        secondaryTextLabel.isHidden = false
        accessoryType = .disclosureIndicator
    }
    
}
