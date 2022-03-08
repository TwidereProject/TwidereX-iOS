//
//  TableViewEntryTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

public final class TableViewEntryTableViewCell: TableViewPlainCell {
    
    override func _init() {
        super._init()
        
        secondaryTextLabel.isHidden = false
        accessoryType = .disclosureIndicator
    }
    
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI
import TwidereCore

struct ListEntryTableViewCell_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview {
            let cell = TableViewEntryTableViewCell()
            cell.primaryTextLabel.configure(content: PlaintextMetaContent(string: "Primary"))
            cell.secondaryTextLabel.text = "Secondary"
            return cell
        }
        .previewLayout(.fixed(width: 500, height: 100))
    }
    
}

#endif
