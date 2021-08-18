//
//  MastodonUser.swift
//  MastodonUser
//
//  Created by Cirno MainasuK on 2021-8-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension MastodonUser.Property {
    init(entity: Mastodon.Entity.Account, domain: String, networkDate: Date) {
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
            emojisData: entity.emojis.flatMap { MastodonUser.encode(emojis: $0) },
            fieldsData: entity.fields.flatMap { MastodonUser.encode(fields: $0) },
            statusesCount: NSNumber(value: entity.statusesCount),
            followingCount: NSNumber(value: entity.followingCount),
            followersCount: NSNumber(value: entity.followersCount),
            locked: entity.locked,
            bot: entity.bot ?? false,
            suspended: entity.suspended ?? false,
            createdAt: entity.createdAt,
            updatedAt: networkDate
        )
    }
}

extension MastodonUser: MastodonEmojiContainer { }
extension MastodonUser: MastodonFieldContainer { }
