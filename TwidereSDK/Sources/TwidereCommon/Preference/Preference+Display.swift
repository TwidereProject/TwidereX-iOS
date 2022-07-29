//
//  Preference+Display.swift
//  TwidereCommon
//
//  Created by Cirno MainasuK on 2021-11-3.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

extension UserDefaults {

    @objc public enum AvatarStyle: Int, CaseIterable {
        case circle
        case roundedSquare
    }

    @objc dynamic public var avatarStyle: AvatarStyle {
        get {
            guard let rawValue: Int = self[#function] else {
                return .circle
            }
            return AvatarStyle(rawValue: rawValue) ?? .circle
        }
        set {
            self[#function] = newValue.rawValue
        }
    }

}

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
