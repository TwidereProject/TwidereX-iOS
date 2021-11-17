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
    
    private init() {
        theme = CurrentValueSubject(UserDefaults.shared.theme)
    }
    
    func set(theme: Theme) {
        UserDefaults.shared.theme = theme
        self.theme.value = theme
        apply(theme: theme)
    }
    
    func apply(theme: Theme) {
        // set navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
        
        // set tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        let tabBarItemAppearance = UITabBarItemAppearance()
//        tabBarItemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.clear]
//        tabBarItemAppearance.focused.titleTextAttributes = [.foregroundColor: UIColor.clear]
//        tabBarItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
//        tabBarItemAppearance.disabled.titleTextAttributes = [.foregroundColor: UIColor.clear]
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        // UITabBar.appearance().barTintColor = theme.tabBarBackgroundColor
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
