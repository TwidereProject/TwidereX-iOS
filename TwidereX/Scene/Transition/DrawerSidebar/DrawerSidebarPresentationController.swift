//
//  DrawerSidebarPresentationController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-19.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class DrawerSidebarPresentationController: UIPresentationController {
    
    override var overrideTraitCollection: UITraitCollection? {
        get {
            if UserDefaults.shared.useTheSystemFontSize {
                return nil
            } else {
                let customContentSizeCatagory = UserDefaults.shared.customContentSizeCatagory
                return UITraitCollection(preferredContentSizeCategory: customContentSizeCatagory)
            }
        }
        set {
            
        }
    }
    
}
