//
//  Preference+Display.swift
//  
//
//  Created by MainasuK on 2021-12-6.
//

import Foundation
import TwidereLocalization

extension UserDefaults.AvatarStyle {
    
    public var text: String {
        switch self {
        case .circle:           return L10n.Scene.Settings.Display.Text.circle
        case .roundedSquare:    return L10n.Scene.Settings.Display.Text.roundedSquare
        }
    }

}
