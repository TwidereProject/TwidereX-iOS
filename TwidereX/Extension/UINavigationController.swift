//
//  UINavigationController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

extension UINavigationController.Operation: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .push:     return "push"
        case .pop:      return "pop"
        case .none:     return "none"
        }
    }
}
