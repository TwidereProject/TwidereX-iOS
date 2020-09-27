//
//  TwitterUser.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-4.
//

import Foundation
import CoreDataStack
import TwitterAPI

extension TwitterUser.Property {
    init(entity: Twitter.Entity.User, networkDate: Date) {
        self.init(
            idStr: entity.idStr,
            name: entity.name,
            screenName: entity.screenName,
            bioDescription: entity.userDescription,
            url: entity.url,
            location: entity.location,
            createdAt: entity.createdAt,
            following: entity.following,
            friendsCount: entity.friendsCount.flatMap { NSNumber(value: $0) },
            followersCount: entity.followersCount.flatMap { NSNumber(value: $0) },
            listedCount: entity.listedCount.flatMap { NSNumber(value: $0) },
            favouritesCount: entity.favouritesCount.flatMap { NSNumber(value: $0) },
            statusesCount: entity.statusesCount.flatMap { NSNumber(value: $0) },
            profileImageURLHTTPS: entity.profileImageURLHTTPS,
            profileBannerURL: entity.profileBannerURL,
            networkDate: networkDate
        )
    }
}
