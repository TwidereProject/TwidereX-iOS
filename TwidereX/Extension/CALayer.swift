//
//  CALayer.swift
//  Mailway
//
//  Created by Cirno MainasuK on 2020-7-10.
//  Copyright © 2020 Dimension. All rights reserved.
//

import UIKit

extension CALayer {
    
    func setupShadow(color: UIColor = .black, alpha: Float = 0.5,
                         x: CGFloat = 0, y: CGFloat = 2,
                         blur: CGFloat = 4, spread: CGFloat = 0,
                         roundedRect: CGRect, byRoundingCorners corners: UIRectCorner, cornerRadii: CGSize) {
        // assert(roundedRect != .zero)
        shadowColor        = color.cgColor
        shadowOpacity      = alpha
        shadowOffset       = CGSize(width: x, height: y)
        shadowRadius       = blur / 2
        rasterizationScale = UIScreen.main.scale
        shouldRasterize    = true
        masksToBounds      = false
        
        if spread == 0 {
            shadowPath = UIBezierPath(roundedRect: roundedRect, byRoundingCorners: corners, cornerRadii: cornerRadii).cgPath
        } else {
            let rect = roundedRect.insetBy(dx: -spread, dy: -spread)
            shadowPath = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: cornerRadii).cgPath
        }
    }
    
}
