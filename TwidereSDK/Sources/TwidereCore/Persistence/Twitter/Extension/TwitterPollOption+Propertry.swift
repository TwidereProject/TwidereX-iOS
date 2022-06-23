//
//  TwitterPollOption+Propertry.swift
//  
//
//  Created by MainasuK on 2022-6-8.
//

import Foundation
import TwitterSDK
import CoreDataStack

extension TwitterPollOption.Property {
    public init(
        entity: Twitter.Entity.V2.Tweet.Poll.Option,
        networkDate: Date
    ) {
        self.init(
            position: Int64(entity.position),
            label: entity.label,
            votes: Int64(entity.votes),
            createdAt: networkDate,
            updatedAt: networkDate
        )
    }
}
