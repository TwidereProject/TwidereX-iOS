//
//  UIView.swift
//  Mailway
//
//  Created by Cirno MainasuK on 2020-7-2.
//  Copyright © 2020 Dimension. All rights reserved.
//

import UIKit

extension UIView {
    
    static var separatorLine: UIView {
        let line = UIView()
        line.backgroundColor = .separator
        return line
    }
    
    static func separatorLineHeight(of view: UIView) -> CGFloat {
        return 1.0 / view.traitCollection.displayScale
    }
    
}
