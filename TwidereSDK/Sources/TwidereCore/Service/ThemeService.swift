//
//  ThemeService.swift
//  ThemeService
//
//  Created by Cirno MainasuK on 2021-8-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import TwidereCommon
import TwidereAsset

@MainActor
public final class ThemeService {
    public static let shared = ThemeService()
    
    public let theme: CurrentValueSubject<Theme, Never>
    
    private init() {
        theme = CurrentValueSubject(UserDefaults.shared.theme)
    }
    
    public func set(theme: Theme) {
        UserDefaults.shared.theme = theme
        self.theme.value = theme
        apply(theme: theme)
    }
    
    public func apply(theme: Theme) {
        // set navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
        
        // set tab bar appearance
        let tabBarAppearance = ThemeService.setupTabBarAppearance()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

}

extension Theme {
    public var accentColor: UIColor {
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

extension ThemeService {
    public static func setupTabBarAppearance() -> UITabBarAppearance {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.stackedLayoutAppearance = {
            let tabBarItemAppearance = UITabBarItemAppearance()
            if !UserDefaults.shared.preferredTabBarLabelDisplay {
                tabBarItemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.clear]
                tabBarItemAppearance.focused.titleTextAttributes = [.foregroundColor: UIColor.clear]
                tabBarItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
                tabBarItemAppearance.disabled.titleTextAttributes = [.foregroundColor: UIColor.clear]
            }
            return tabBarItemAppearance
        }()
        return tabBarAppearance
    }
}
