//
//  NotificationObject.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack

public enum NotificationObject: Hashable {
    case twitter(object: TwitterStatus)
    case mastodon(object: MastodonNotification)
}

extension NotificationObject {
    public var asRecord: NotificationRecord {
        switch self {
        case .twitter(let object):
            return .twitter(record: object.asRecrod)
        case .mastodon(let object):
            return .mastodon(record: object.asRecrod)
        }
    }
}

extension NotificationObject {
    public var status: StatusObject? {
        switch self {
        case .twitter(let object):
            let status = object
            return .twitter(object: status)
        case .mastodon(let object):
            guard let status = object.status else { return nil }
            return .mastodon(object: status)
        }   // end swich
    }   // end func
}
