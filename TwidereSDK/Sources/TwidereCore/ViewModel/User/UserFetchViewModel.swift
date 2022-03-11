//
//  UserFetchViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import TwitterSDK
import MastodonSDK

public enum UserFetchViewModel {
    
    static let logger = Logger(subsystem: "UserFetchViewModel", category: "ViewModel")
    
    public enum Result {
        case twitter([Twitter.Entity.User]) // v1
        case twitterV2([Twitter.Entity.V2.User]) // v2
        case mastodon([Mastodon.Entity.Account])
    }
}

extension UserFetchViewModel {
    public enum Friendship { }
    public enum List { }
    public enum Search { }
}
