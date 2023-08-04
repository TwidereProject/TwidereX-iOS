//
//  Preference+Appearance.swift
//  
//
//  Created by MainasuK on 2022-4-1.
//

import Foundation
import TwidereLocalization

extension UserDefaults.TranslateButtonPreference {
    public var text: String {
        switch self {
        case .auto:     return L10n.Scene.Settings.Appearance.Translation.auto
        case .always:   return L10n.Scene.Settings.Appearance.Translation.always
        case .off:      return L10n.Scene.Settings.Appearance.Translation.off
        }
    }
}

extension UserDefaults.TranslationServicePreference {
    public var text: String {
        switch self {
        case .bing:     return "Bing"
        case .deepl:    return "DeepL"
        case .google:   return "Google"
        }
    }
}
