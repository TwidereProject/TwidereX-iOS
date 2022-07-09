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
    public init(
        entity: Mastodon.Entity.Notification,
        domain: String,
        userID: MastodonUser.ID,
        networkDate: Date
    ) {
        let notificationType = MastodonNotificationType(rawValue: entity.type.rawValue) ?? MastodonNotificationType._other(entity.type.rawValue)
        self.init(
            id: entity.id,
            domain: domain,
            userID: userID,
            notificationType: notificationType,
            createdAt: entity.createdAt,
            updatedAt: networkDate
        )
    }
}
