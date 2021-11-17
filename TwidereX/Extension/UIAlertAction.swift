//
//  UIAlertAction.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-21.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

extension UIAlertAction {
    static var cancel: UIAlertAction {
        UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
    }
}
