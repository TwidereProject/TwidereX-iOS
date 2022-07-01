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
        case twitter(TwitterStatus)
        case mastodon(MastodonStatus)
        case mastodonNotification(MastodonNotification)
        case none
    }
    
    public var content: Content {
        switch kind {
        case .home:
            if let status = twitterStatus {
                return .twitter(status)
            } else if let status = mastodonStatus {
                return .mastodon(status)
            } else {
                return .none
            }
        case .notificationAll, .notificationMentions:
            if let status = twitterStatus {
                return .twitter(status)
            } else if let status = mastodonStatus {
                assertionFailure("The status should nest in mastodonNotification")
                return .mastodon(status)
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
    public enum ObjectContent {
        case status(StatusObject)
        case notification(NotificationObject)
        case none
    }
    
    public var objectContent: ObjectContent {
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
                return .status(.twitter(object: status))
            } else if let status = mastodonStatus {
                assertionFailure("The status should nest in mastodonNotification")
                return .status(.mastodon(object: status))
            } else if let notification = mastodonNotification {
                if let status = notification.status {
                    return .status(.mastodon(object: status))
                } else {
                    return .notification(.mastodon(object: notification))
                }
            } else {
                return .none
            }
        case .none:
            return .none
        }
    }
    
}

extension Feed {
    public var statusObject: StatusObject? {
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
    
    @available(*, deprecated, message: "")
    public var notificationObject: NotificationObject? {
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
