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

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ListEntryTableViewCell_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview {
            let cell = ListEntryTableViewCell()
            cell.titleLabel.text = "Title"
            cell.secondaryTextLabel.text = "Secondary"
            return cell
        }
        .previewLayout(.fixed(width: 500, height: 100))
    }
    
}

#endif
