//
//  UIButton.swift
//  
//
//  Created by MainasuK on 2021/11/22.
//

import UIKit

/// https://noahgilmore.com/blog/uibutton-padding/
extension UIButton {
    public func setInsets(
        forContentPadding contentPadding: UIEdgeInsets,
        imageTitlePadding: CGFloat
    ) {
        switch UIApplication.shared.userInterfaceLayoutDirection {
        case .rightToLeft:
            self.contentEdgeInsets = UIEdgeInsets(
                top: contentPadding.top,
                left: contentPadding.left + imageTitlePadding,
                bottom: contentPadding.bottom,
                right: contentPadding.right
            )
            self.titleEdgeInsets = UIEdgeInsets(
                top: 0,
                left: -imageTitlePadding,
                bottom: 0,
                right: imageTitlePadding
            )
        default:
            self.contentEdgeInsets = UIEdgeInsets(
                top: contentPadding.top,
                left: contentPadding.left,
                bottom: contentPadding.bottom,
                right: contentPadding.right + imageTitlePadding
            )
            self.titleEdgeInsets = UIEdgeInsets(
                top: 0,
                left: imageTitlePadding,
                bottom: 0,
                right: -imageTitlePadding
            )
        }
    }
}
