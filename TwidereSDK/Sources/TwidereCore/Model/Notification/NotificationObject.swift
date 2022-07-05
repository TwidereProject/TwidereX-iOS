//
//  NotificationObject.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack

public enum NotificationObject {
    case mastodon(object: MastodonNotification)
}

extension NotificationObject {
    public var status: StatusObject? {
        switch self {
        case .mastodon(let object):
            return object.status.flatMap { .mastodon(object: $0) }
        }   // end swich
    }   // end func
}
