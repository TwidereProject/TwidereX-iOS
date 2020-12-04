//
//  UIFont.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-23.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

// refs: https://stackoverflow.com/questions/26371024/limit-supported-dynamic-type-font-sizes
extension UIFont {

  static func preferredFont(withTextStyle textStyle: UIFont.TextStyle, maxSize: CGFloat) -> UIFont {
    // Get the descriptor
    let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)

    // Return a font with the minimum size
    return UIFont(descriptor: fontDescriptor, size: min(fontDescriptor.pointSize, maxSize))
  }

}
