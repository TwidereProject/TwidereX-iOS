//
//  MastodonStatus+Property.swift
//  MastodonStatus+Property
//
//  Created by Cirno MainasuK on 2021-8-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack
import CoreGraphics
import MastodonSDK

extension MastodonStatus.Property {
    init(domain: String,
         entity: Mastodon.Entity.Status,
         networkDate: Date
    ) {
        self.init(
            id: entity.id,
            domain: domain,
            uri: entity.uri,
            content: entity.content ?? "",
            likeCount: entity.favouritesCount,
            replyCount: entity.repliesCount ?? 0,
            repostCount: entity.reblogsCount,
            visibility: entity.mastodonVisibility,
            url: entity.url,
            text: entity.text,
            language: entity.language,
            createdAt: entity.createdAt,
            updatedAt: networkDate
        )
    }
}

extension Mastodon.Entity.Status {
    var mastodonVisibility: MastodonVisibility {
        let rawValue = visibility?.rawValue ?? ""
        return MastodonVisibility(rawValue: rawValue) ?? ._other(rawValue)
    }
}
