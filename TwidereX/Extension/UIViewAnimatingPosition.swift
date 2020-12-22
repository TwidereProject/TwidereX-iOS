//
//  UIViewAnimatingPosition.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

extension UIViewAnimatingPosition: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .current:      return "current"
        case .start:        return "start"
        case .end:          return "end"
        }
    }
}
