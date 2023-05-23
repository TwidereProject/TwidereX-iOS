//
//  NSLayoutConstraint.swift
//  
//
//  Created by MainasuK on 2021/11/18.
//

import UIKit

extension NSLayoutConstraint {
    public func priority(_ priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
}

extension NSLayoutConstraint {
    public func identifier(_ identifier: String) -> Self {
        self.identifier = identifier
        return self
    }
}
