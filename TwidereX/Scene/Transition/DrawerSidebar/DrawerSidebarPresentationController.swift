//
//  DrawerSidebarPresentationController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-19.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit

final class DrawerSidebarPresentationController: UIPresentationController {

    override var shouldRemovePresentersView: Bool { return true }
    
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

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
