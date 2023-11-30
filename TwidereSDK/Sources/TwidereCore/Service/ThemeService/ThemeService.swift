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

public final class ThemeService: ObservableObject {
    public static let shared = ThemeService()
    
    @Published public var theme: Theme
    
    private init() {
        self.theme = .grandBudapestHotel
    }

}

//extension Theme {
//    public var accentColor: UIColor {
//        switch self {
//        case .daylight:         return Asset.Colors.Theme.daylight.color
//        case .maskBlue:         return Asset.Colors.Theme.maskBlue.color
//        case .violet:           return Asset.Colors.Theme.violet.color
//        case .grandBudapest:    return Asset.Colors.Theme.grandBudapest.color
//        case .vulcan:           return Asset.Colors.Theme.vulcan.color
//        case .goldenSpirit:     return Asset.Colors.Theme.goldenSpirit.color
//        case .lime:             return Asset.Colors.Theme.lime.color
//        case .seafoam:          return Asset.Colors.Theme.seafoam.color
//        }
//    }
//}

