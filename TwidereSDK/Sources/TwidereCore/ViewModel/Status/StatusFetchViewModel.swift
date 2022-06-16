//
//  StatusFetchViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import CoreDataStack
import TwitterSDK
import MastodonSDK

public enum StatusFetchViewModel {
    
    static let logger = Logger(subsystem: "StatusListFetchViewModel", category: "ViewModel")
    
    public enum Result {
        case twitter([Twitter.Entity.Tweet]) // v1
        case twitterV2([Twitter.Entity.V2.Tweet]) // v2
        case mastodon([Mastodon.Entity.Status])
    }
    
}
