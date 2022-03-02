//
//  MastodonNotification+Property.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/16.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension MastodonNotification.Property {
    public init(entity: Mastodon.Entity.Notification, domain: String, networkDate: Date) {
        let notificationType = MastodonNotificationType(rawValue: entity.type.rawValue) ?? MastodonNotificationType._other(entity.type.rawValue)
        self.init(
            domain: domain,
            id: entity.id,
            userID: entity.account.id,
            notificationType: notificationType,
            createdAt: entity.createdAt,
            updatedAt: networkDate
        )
    }
}
