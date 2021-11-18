//
//  Preference+Display.swift
//  AppShared
//
//  Created by Cirno MainasuK on 2021-11-3.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

extension UserDefaults {
    
    @objc dynamic public var preferredStaticAvatar: Bool {
        get {
            return bool(forKey: #function)
        }
        set { self[#function] = newValue }
    }
    
    @objc dynamic public var preferredStaticEmoji: Bool {
        get {
            // default false
            // without set register to profile timeline performance
            return bool(forKey: #function)
        }
        set { self[#function] = newValue }
    }
    
}
