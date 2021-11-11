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
        case mastodonNotification(MastodonNotification)
        case none
    }
    
    var content: Content {
        switch kind {
        case .home:
            if let status = twitterStatus {
                return .twitter(status)
            } else if let status = mastodonStatus {
                return .mastodon(status)
            } else {
                return .none
            }
        case .notification:
            if let status = twitterStatus {
                return .twitter(status)
            } else if let notification = mastodonNotification {
                return .mastodonNotification(notification)
            } else {
                return .none
            }
        case .none:
            return .none
        }
    }
}

extension Feed {
    var statusObject: StatusObject? {
        switch acct {
        case .none:
            return nil
        case .twitter:
            guard let status = twitterStatus else { return nil }
            return .twitter(object: status)
        case .mastodon:
            if let status = mastodonStatus {
                return .mastodon(object: status)
            } else if let notification = mastodonNotification,
                      let status = notification.status {
                return .mastodon(object: status)
            } else {
                return nil
            }
        }
    }
    
    var notificationObject: NotificationObject? {
        switch acct {
        case .none:
            return nil
        case .twitter:
            return nil
        case .mastodon:
            guard let notification = mastodonNotification else { return nil }
            return .mastodon(object: notification)
        }
    }
}
