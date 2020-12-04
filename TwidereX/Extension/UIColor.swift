//
//  UIColor.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-25.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

extension UIColor {
    var complementary: UIColor {
        let ciColor = CIColor(color: self)
        return UIColor(
            red: 1.0 - ciColor.red,
            green: 1.0 - ciColor.green,
            blue: 1.0 - ciColor.blue,
            alpha: 1.0
        )
    }
}
