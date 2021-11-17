//
//  Preference+Theme.swift
//  
//
//  Created by Cirno MainasuK on 2021-11-3.
//

import UIKit

extension UserDefaults {

    @objc dynamic public var theme: Theme {
        get {
            guard let rawValue: Int = self[#function] else {
                return .daylight
            }
            return Theme(rawValue: rawValue) ?? .daylight
        }
        set {
            self[#function] = newValue.rawValue
        }
    }
}

// Keep rawValue reserved for API compatibility
@objc public enum Theme: Int, CaseIterable {
    case daylight       = 0
    case maskBlue       = 1
    case violet         = 2
    case grandBudapest  = 3
    case vulcan         = 4
    case goldenSpirit   = 5
    case lime           = 6
    case seafoam        = 7
}
