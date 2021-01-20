//
//  UIFont.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-23.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

extension UIFont {

    // refs: https://stackoverflow.com/questions/26371024/limit-supported-dynamic-type-font-sizes
  static func preferredFont(withTextStyle textStyle: UIFont.TextStyle, maxSize: CGFloat) -> UIFont {
    // Get the descriptor
    let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)

    // Return a font with the minimum size
    return UIFont(descriptor: fontDescriptor, size: min(fontDescriptor.pointSize, maxSize))
  }
    
    static func preferredMonospacedFont(withTextStyle textStyle: UIFont.TextStyle, compatibleWith traitCollection: UITraitCollection? = nil) -> UIFont {
        let fontDescription = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle).addingAttributes([
            UIFontDescriptor.AttributeName.featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.featureIdentifier:
                        kNumberSpacingType,
                    UIFontDescriptor.FeatureKey.typeIdentifier:
                        kMonospacedNumbersSelector
                ]
            ]
        ])
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: UIFont(descriptor: fontDescription, size: 0), compatibleWith: traitCollection)
    }

}
