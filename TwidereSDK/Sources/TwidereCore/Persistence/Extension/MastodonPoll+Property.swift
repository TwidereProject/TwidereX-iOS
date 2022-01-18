//
//  MastodonPoll.swift
//  
//
//  Created by MainasuK on 2021-12-9.
//

import Foundation
import MastodonSDK
import CoreDataStack

extension MastodonPoll.Property {
    public init(
        entity: Mastodon.Entity.Poll,
        domain: String,
        networkDate: Date
    ) {
        self.init(
            domain: domain,
            id: entity.id,
            expired: entity.expired,
            multiple: entity.multiple,
            votesCount: Int64(entity.votesCount),
            votersCount: Int64(entity.votersCount ?? -1),
            expiresAt: entity.expiresAt,
            createdAt: networkDate,
            updatedAt: networkDate
        )
    }
}
