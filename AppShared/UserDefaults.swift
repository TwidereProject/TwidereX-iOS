//
//  UserDefaults.swift
//  AppShared
//
//  Created by Cirno MainasuK on 2021-11-3.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

extension UserDefaults {
    public static let shared = UserDefaults(suiteName: AppCommon.groupID)!
}

