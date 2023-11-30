//
//  UITabBarItemAppearance.swift
//  
//
//  Created by MainasuK on 2023-09-19.
//

import UIKit

extension UITabBarAppearance {
    public static var defaultAppearance: UITabBarAppearance {
        let theme = ThemeService.shared.theme
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        if let barBackgroundColor = theme.barBackgroundColor {
            tabBarAppearance.backgroundColor = barBackgroundColor
        }
        tabBarAppearance.stackedLayoutAppearance = {
            let tabBarItemAppearance = UITabBarItemAppearance()
            tabBarItemAppearance.selected.iconColor = theme.highlight
            tabBarItemAppearance.focused.iconColor = theme.highlight
            tabBarItemAppearance.normal.iconColor = theme.comment
            tabBarItemAppearance.disabled.iconColor = theme.commentDisabled
            if !UserDefaults.shared.preferredTabBarLabelDisplay {
                tabBarItemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.clear]
                tabBarItemAppearance.focused.titleTextAttributes = [.foregroundColor: UIColor.clear]
                tabBarItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
                tabBarItemAppearance.disabled.titleTextAttributes = [.foregroundColor: UIColor.clear]
            } else {
                tabBarItemAppearance.selected.titleTextAttributes = [.foregroundColor: theme.highlight]
                tabBarItemAppearance.focused.titleTextAttributes = [.foregroundColor: theme.highlight]
                tabBarItemAppearance.normal.titleTextAttributes = [.foregroundColor: theme.comment]
                tabBarItemAppearance.disabled.titleTextAttributes = [.foregroundColor: theme.commentDisabled]
            }
            return tabBarItemAppearance
        }()

        return tabBarAppearance
    }
}

