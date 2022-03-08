//
//  MastodonList+Property.swift
//  
//
//  Created by MainasuK on 2022-3-8.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension MastodonList.Property {
    public init(
        entity: Mastodon.Entity.List,
        domain: String,
        networkDate: Date
    ) {
        self.init(
            id: entity.id,
            domain: domain,
            title: entity.title,
            updatedAt: networkDate
        )
    }
}
