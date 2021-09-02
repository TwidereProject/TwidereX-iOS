//
//  Feed.swift
//  Feed
//
//  Created by Cirno MainasuK on 2021-9-1.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack

extension Feed {
    enum Content {
        case twitter(TwitterStatus)
        case mastodon(MastodonStatus)
        case none
    }
    
    var content: Content {
        if let status = twitterStatus {
            return .twitter(status)
        } else if let status = mastodonStatus {
            return .mastodon(status)
        } else {
            return .none
        }
    }
}
