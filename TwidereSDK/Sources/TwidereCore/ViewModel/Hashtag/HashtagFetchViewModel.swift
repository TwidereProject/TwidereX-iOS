//
//  HashtagFetchViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-5.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import MastodonSDK

public enum HashtagFetchViewModel {
    
    static let logger = Logger(subsystem: "HashtagFetchViewModel", category: "ViewModel")
    
    public enum Result {
        case mastodon([Mastodon.Entity.Tag])
    }
}

extension HashtagFetchViewModel {
    public enum Search { }
}
