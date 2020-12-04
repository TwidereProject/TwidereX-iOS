//
//  UILabel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-19.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

extension UILabel {
    
    func dynamicFont(forTextStyle textStyle: UIFont.TextStyle) {
        font = .preferredFont(forTextStyle: textStyle)
        adjustsFontForContentSizeCategory = true
    }
    
}
