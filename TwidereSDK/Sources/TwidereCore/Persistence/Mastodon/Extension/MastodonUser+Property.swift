//
//  MastodonUser+Property.swift
//  MastodonUser
//
//  Created by Cirno MainasuK on 2021-8-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension MastodonUser.Property {
    public init(entity: Mastodon.Entity.Account, domain: String, networkDate: Date) {
        self.init(
            domain: domain,
            id: entity.id,
            acct: entity.acct,
            username: entity.username,
            displayName: entity.displayName,
            note: entity.note,
            url: entity.url,
            avatar: entity.avatar,
            avatarStatic: entity.avatarStatic,
            header: entity.header,
            headerStatic: entity.headerStatic,
            statusesCount: Int64(entity.statusesCount),
            followingCount: Int64(entity.followingCount),
            followersCount: Int64(entity.followersCount),
            locked: entity.locked,
            bot: entity.bot ?? false,
            suspended: entity.suspended ?? false,
            createdAt: entity.createdAt,
            updatedAt: networkDate,
            emojisTransient: entity.mastodonEmojis,
            fieldsTransient: entity.mastodonFields
        )
    }
}
