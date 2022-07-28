//
//  Preference+Behaviors.swift
//  
//
//  Created by MainasuK on 2022-7-27.
//

import Foundation

// MARK: - Tab bar: label
extension UserDefaults {
    
    @objc dynamic public var preferredTabBarLabelDisplay: Bool {
        get { return bool(forKey: #function) }
        set { self[#function] = newValue }
    }
    
}

// MARK: - Tab bar: Tap Scroll
extension UserDefaults {
    
    @objc public enum TabBarTapScrollPreference: Int, Hashable, CaseIterable {
        case single
        case double
    }
    
    @objc dynamic public var tabBarTapScrollPreference: TabBarTapScrollPreference {
        get {
            guard let rawValue: Int = self[#function] else { return .single }
            return TabBarTapScrollPreference(rawValue: rawValue) ?? .single
        }
        set { self[#function] = newValue.rawValue }
    }
    
}

// MARK: - Tab bar: Timeline Refreshing
extension UserDefaults {
    
    @objc dynamic public var preferredTimelineAutoRefresh: Bool {
        get {
            register(defaults: [#function: true])
            return bool(forKey: #function)
        }
        set { self[#function] = newValue }
    }
    
    @objc public enum TimelineRefreshInterval: Int, Hashable, CaseIterable {
        case _30s
        case _60s
        case _120s
        case _300s
        
        public var seconds: TimeInterval {
            switch self {
            case ._30s:     return 30
            case ._60s:     return 60
            case ._120s:    return 120
            case ._300s:    return 300
            }
        }
    }
    
    @objc dynamic public var timelineRefreshInterval: TimelineRefreshInterval {
        get {
            guard let rawValue: Int = self[#function] else { return ._60s }
            return TimelineRefreshInterval (rawValue: rawValue) ?? ._60s
        }
        set { self[#function] = newValue.rawValue }
    }
    
    @objc dynamic public var preferredTimelineResetToTop: Bool {
        get {
            return bool(forKey: #function)
        }
        set { self[#function] = newValue }
    }
    
}
