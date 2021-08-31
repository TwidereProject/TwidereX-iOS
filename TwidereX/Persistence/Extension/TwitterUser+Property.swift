//
//  TwitterUser+Property.swift
//  TwitterUser
//
//  Created by Cirno MainasuK on 2021-8-20.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import TwitterSDK

// MARK: - V1

extension TwitterUser.Property {
    init(
        entity: Twitter.Entity.User,
        networkDate: Date
    ) {
        self.init(
            id: entity.idStr,
            name: entity.name,
            username: entity.screenName,
            bio: entity.userDescription.flatMap { text in
                text.replacingOccurrences(of: "&amp;", with: "&")
                    .replacingOccurrences(of: "&lt;", with: "<")
                    .replacingOccurrences(of: "&gt;", with: ">")
                    .replacingOccurrences(of: "&quot;", with: "\"")
                    .replacingOccurrences(of: "&apos;", with: "'")
            },
            createdAt: entity.createdAt,
            location: entity.location,
            profileImageURL: entity.profileImageURLHTTPS,
            protected: entity.protected ?? false,
            url: entity.url,
            verified: entity.verified ?? false,
            updatedAt: networkDate
        )
    }
}

// MARK: - V2

extension TwitterUser.Property {
    init(
        entity: Twitter.Entity.V2.User,
        networkDate: Date
    ) {
        self.init(
            id: entity.id,
            name: entity.name,
            username: entity.username,
            bio: entity.description.flatMap { text in
                text.replacingOccurrences(of: "&amp;", with: "&")
                    .replacingOccurrences(of: "&lt;", with: "<")
                    .replacingOccurrences(of: "&gt;", with: ">")
                    .replacingOccurrences(of: "&quot;", with: "\"")
                    .replacingOccurrences(of: "&apos;", with: "'")
            },
            createdAt: entity.createdAt,
            location: entity.location,
            profileImageURL: entity.profileImageURL,
            protected: entity.protected ?? false,
            url: entity.url,
            verified: entity.verified ?? false,
            updatedAt: networkDate
        )
    }
}
