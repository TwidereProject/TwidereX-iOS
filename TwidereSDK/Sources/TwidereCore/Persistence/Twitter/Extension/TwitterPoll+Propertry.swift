//
//  TwitterPoll+Propertry.swift
//  
//
//  Created by MainasuK on 2022-6-8.
//

import Foundation
import TwitterSDK
import CoreDataStack

extension TwitterPoll.Property {
    public init(
        entity: Twitter.Entity.V2.Tweet.Poll,
        networkDate: Date
    ) {
        self.init(
            id: entity.id,
            votingStatus: {
                switch entity.votingStatus {
                case .open:     return .open
                case .closed:   return .closed
                }
            }(),
            durationMinutes: Int64(entity.durationMinutes ?? 0),
            endDatetime: entity.endDatetime,
            createdAt: networkDate,
            updatedAt: networkDate
        )
    }
}
