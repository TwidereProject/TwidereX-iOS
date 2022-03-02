//
//  UserFetchViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import TwidereCore
import TwitterSDK
import MastodonSDK

enum UserFetchViewModel {
    
    static let logger = Logger(subsystem: "UserFetchViewModel", category: "ViewModel")
    
    enum Result {
        case twitter([Twitter.Entity.User]) // v1
        case twitterV2([Twitter.Entity.V2.User]) // v2
        case mastodon([Mastodon.Entity.Account])
    }
}

extension UserFetchViewModel {
    enum Search { }
    enum Friendship { }
}
