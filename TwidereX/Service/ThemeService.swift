//
//  ThemeService.swift
//  ThemeService
//
//  Created by Cirno MainasuK on 2021-8-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine

@MainActor
final class ThemeService {
    static let shared = ThemeService()
    
    let theme: CurrentValueSubject<Theme, Never>
    
    init() {
        theme = CurrentValueSubject(UserDefaults.shared.theme)
    }
    
    func set(theme: Theme) {
        UserDefaults.shared.theme = theme
    }
    
    func apply(theme: Theme) {

    }
    
}

// Keep rawValue reserved for API compatibility
@objc enum Theme: Int, CaseIterable {
    case daylight       = 0
    case maskBlue       = 1
    case violet         = 2
    case grandBudapest  = 3
    case vulcan         = 4
    case goldenSpirit   = 5
    case lime           = 6
    case seafoam        = 7
    
    var accentColor: UIColor {
        switch self {
        case .daylight:         return Asset.Colors.Theme.daylight.color
        case .maskBlue:         return Asset.Colors.Theme.maskBlue.color
        case .violet:           return Asset.Colors.Theme.violet.color
        case .grandBudapest:    return Asset.Colors.Theme.grandBudapest.color
        case .vulcan:           return Asset.Colors.Theme.vulcan.color
        case .goldenSpirit:     return Asset.Colors.Theme.goldenSpirit.color
        case .lime:             return Asset.Colors.Theme.lime.color
        case .seafoam:          return Asset.Colors.Theme.seafoam.color
        }
    }
    
}
