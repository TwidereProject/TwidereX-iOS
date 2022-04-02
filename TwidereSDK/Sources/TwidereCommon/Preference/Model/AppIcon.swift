//
//  AppIcon.swift
//  
//
//  Created by MainasuK on 2022-4-2.
//

import Foundation

@objc public enum AppIcon: Int, CaseIterable {
    
    case twidere
    case alternative
    case classic
    case violet
    case daylight
    case seafoam
    case lime
    case goldenSpirit
    case vulcan
    case blush
    case stardust
    case moonLight
    case epigraphy
    case blackIris
    
    public var iconName: String {
        switch self {
        case .twidere:          return "Twidere"
        case .alternative:      return "Alternative"
        case .classic:          return "Classic"
        case .violet:           return "Violet"
        case .daylight:         return "Daylight"
        case .seafoam:          return "Seafoam"
        case .lime:             return "Lime"
        case .goldenSpirit:     return "GoldenSpirit"
        case .vulcan:           return "Vulcan"
        case .blush:            return "Blush"
        case .stardust:         return "Stardust"
        case .moonLight:        return "MoonLight"
        case .epigraphy:        return "Epigraphy"
        case .blackIris:        return "BlackIris"
        }
    }
    
    public var text: String {
        switch self {
        case .twidere:          return "Twidere"
        case .alternative:      return "Alternative"
        case .classic:          return "Classic"
        case .violet:           return "Violet"
        case .daylight:         return "Daylight"
        case .seafoam:          return "Seafoam"
        case .lime:             return "Lime"
        case .goldenSpirit:     return "Golden Spirit"
        case .vulcan:           return "Vulcan"
        case .blush:            return "Blush"
        case .stardust:         return "Stardust"
        case .moonLight:        return "Moon Light"
        case .epigraphy:        return "Epigraphy"
        case .blackIris:        return "Black Iris"
        }
    }
    
}
