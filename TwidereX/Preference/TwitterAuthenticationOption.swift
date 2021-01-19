//
//  TwitterAuthenticationOption.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

extension UserDefaults {

    @objc dynamic var twitterAuthenticationConsumerKey: String? {
        get { return UserDefaults.shared[#function] }
        set { UserDefaults.shared[#function] = newValue }
    }
    
    @objc dynamic var twitterAuthenticationConsumerSecret: String? {
        get { return UserDefaults.shared[#function] }
        set { UserDefaults.shared[#function] = newValue }
    }
    
}
