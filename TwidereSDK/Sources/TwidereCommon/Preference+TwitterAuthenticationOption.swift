//
//  Preference+TwitterAuthenticationOption.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

extension UserDefaults {

    @objc dynamic public var twitterAuthenticationConsumerKey: String? {
        get { return string(forKey: #function) }
        set { self[#function] = newValue }
    }
    
    @objc dynamic public var twitterAuthenticationConsumerSecret: String? {
        get { return string(forKey: #function) }
        set { self[#function] = newValue }
    }
    
}
