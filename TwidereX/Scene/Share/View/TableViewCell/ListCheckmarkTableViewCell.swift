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

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ListCheckmarkTableViewCell_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview {
            let cell = ListCheckmarkTableViewCell()
            cell.titleLabel.text = "Title"
            return cell
        }
        .previewLayout(.fixed(width: 500, height: 100))
    }
    
}

#endif
