//
//  ListCheckmarkTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-31.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class ListCheckmarkTableViewCell: ListTableViewCell {
    
    override func _init() {
        super._init()
        
        accessoryType = .checkmark
    }
    
}
