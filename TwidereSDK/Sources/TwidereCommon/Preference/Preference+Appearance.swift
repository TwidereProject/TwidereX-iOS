//
//  Preference+Appearance.swift
//  
//
//  Created by MainasuK on 2022-4-1.
//

import Foundation

// MARK: - App Icon
extension UserDefaults {
    @objc dynamic public var alternateIconNamePreference: AppIcon {
        get {
            guard let rawValue: Int = self[#function] else { return .twidere }
            return AppIcon(rawValue: rawValue) ?? .twidere
        }
        set { self[#function] = newValue.rawValue }
    }
}

// MARK: - Translation
extension UserDefaults {
    
    // Translate button
    
    @objc public enum TranslateButtonPreference: Int, Identifiable, CaseIterable {
        case auto
        case always
        case off
        
        public var id: String { "\(rawValue)" }
    }
    
    @objc dynamic public var translateButtonPreference: TranslateButtonPreference {
        get {
            guard let rawValue: Int = self[#function] else { return .auto }
            return TranslateButtonPreference(rawValue: rawValue) ?? .auto
        }
        set { self[#function] = newValue.rawValue }
    }
    
    // Service
    
    @objc public enum TranslationServicePreference: Int, Identifiable, CaseIterable {
        case bing
        case deepl
        case google
        
        public var id: String { "\(rawValue)" }
    }
    
    @objc dynamic public var translationServicePreference: TranslationServicePreference {
        get {
            guard let rawValue: Int = self[#function] else { return .google }
            return TranslationServicePreference(rawValue: rawValue) ?? .google
        }
        set { self[#function] = newValue.rawValue }
    }
    
}
