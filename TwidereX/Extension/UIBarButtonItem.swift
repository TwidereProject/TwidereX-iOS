//
//  UIBarButtonItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
    
    static func closeBarButtonItem(target: Any?, action: Selector?) -> UIBarButtonItem {
        let barButtonItem = UIBarButtonItem(
            image: Asset.Editing.xmark.image.withRenderingMode(.alwaysTemplate),
            style: .plain,
            target: target,
            action: action
        )
        barButtonItem.tintColor = .label
        return barButtonItem
    }
    
    static func composeBarButtonItem(target: Any?, action: Selector?) -> UIBarButtonItem {
        let barButtonItem = UIBarButtonItem(
            image: Asset.ObjectTools.paperplane.image.withRenderingMode(.alwaysTemplate),
            style: .plain,
            target: target,
            action: action
        )
        barButtonItem.tintColor = Asset.Colors.hightLight.color
        return barButtonItem
    }
    
}
