//
//  TwitterList.swift
//  
//
//  Created by MainasuK on 2022-2-28.
//

import Foundation
import CoreDataStack
import TwitterSDK

extension TwitterList.Property {
    public init(
        entity: Twitter.Entity.V2.List,
        networkDate: Date
    ) {
        self.init(
            id: entity.id,
            name: entity.name,
            private: entity.private ?? false,
            memberCount: entity.memberCount.flatMap { Int64($0) } ?? 0,
            followerCount: entity.followerCount.flatMap { Int64($0) } ?? 0,
            theDescription: entity.description,
            createdAt: entity.createdAt,
            updatedAt: networkDate
        )
    }
}
