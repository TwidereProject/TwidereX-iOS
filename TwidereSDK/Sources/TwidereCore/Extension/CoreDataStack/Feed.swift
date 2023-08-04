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
    public enum Content {
        case status(StatusObject)
        case notification(NotificationObject)
        case none
    }
    
    public var content: Content {
        switch kind {
        case .home:
            if let status = twitterStatus {
                return .status(.twitter(object: status))
            } else if let status = mastodonStatus {
                return .status(.mastodon(object: status))
            } else {
                return .none
            }
        case .notificationAll, .notificationMentions:
            if let status = twitterStatus {
                return .notification(.twitter(object: status))
            } else if let notification = mastodonNotification {
                return .notification(.mastodon(object: notification))
            } else {
                return .none
            }
        case .none:
            return .none
        }
    }
}
