//
//  APIService+CoreData+V2+TwitterUser.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-19.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import CoreDataStack
import CommonOSLog
import TwitterAPI

extension APIService.CoreData.V2 {
    
    static func createOrMergeTwitterUser(
        into managedObjectContext: NSManagedObjectContext,
        for requestTwitterUser: TwitterUser?,
        user: Twitter.Entity.V2.User,
        networkDate: Date,
        log: OSLog
    ) -> (user: TwitterUser, isCreated: Bool) {
        let processEntityTaskSignpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "process twitter user %{public}s", user.id)
        defer {
            os_signpost(.end, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "process twitter user %{public}s", user.id)
        }
        
        // fetch old twitter user
        let oldTwitterUser: TwitterUser? = {
            let request = TwitterUser.sortedFetchRequest
            request.predicate = TwitterUser.predicate(idStr: user.id)
            request.returnsObjectsAsFaults = false
            do {
                return try managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()
        
        fatalError()
//        if let oldTwitterUser = oldTwitterUser {
//            // merge old twitter usre
//            APIService.CoreData.V2.mergeTwitterUser(for: requestTwitterUser, old: oldTwitterUser, user: user, networkDate: networkDate)
//            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "find old twitter user %{public}s: name %s", user.id, oldTwitterUser.name ?? "<nil>")
//            return (oldTwitterUser, false)
//        } else {
//            let twitterUserProperty = TwitterUser.Property(entity: user, networkDate: networkDate)
//            let twitterUser = TwitterUser.insert(
//                into: managedObjectContext,
//                property: twitterUserProperty,
//                following: (entity.following ?? false) ? requestTwitterUser : nil,
//                followRequestSent: (entity.followRequestSent ?? false) ? requestTwitterUser : nil
//            )
//            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeTwitterUser", signpostID: processEntityTaskSignpostID, "did insert new twitter user %{public}s: name %s", twitterUser.id.uuidString, twitterUserProperty.name ?? "<nil>")
//            return (twitterUser, true)
//        }
    }
    
    static func mergeTwitterUser(for requestTwitterUser: TwitterUser?, old user: TwitterUser, entity: Twitter.Entity.V2.User, networkDate: Date) {
        guard networkDate > user.updatedAt else { return }
        // only fulfill API supported fields
        user.update(name: entity.name)
        user.update(username: entity.username)
        
        entity.createdAt.flatMap { user.update(createdAt: $0) }
        entity.description.flatMap { user.update(bioDescription: $0) }
        entity.url.flatMap { user.update(url: $0) }
        entity.location.flatMap { user.update(location: $0) }
        entity.protected.flatMap { user.update(protected: $0) }
//        entity.friendsCount.flatMap { user.update(friendsCount: $0) }
//        entity.followersCount.flatMap { user.update(followersCount: $0) }
//        entity.listedCount.flatMap { user.update(listedCount: $0) }
//        entity.favouritesCount.flatMap { user.update(favouritesCount: $0) }
//        entity.statusesCount.flatMap { user.update(statusesCount: $0) }
//        entity.profileImageURLHTTPS.flatMap { user.update(profileImageURLHTTPS: $0) }
//        entity.profileBannerURL.flatMap { user.update(profileBannerURL: $0) }
//
//        // relationship with requestTwitterUser
//        if let requestTwitterUser = requestTwitterUser {
//            entity.following.flatMap { user.update(following: $0, twitterUser: requestTwitterUser) }
//            entity.followRequestSent.flatMap { user.update(followRequestSent: $0, twitterUser: requestTwitterUser) }
//        }
//        // TODO: merge more fileds
//
//
//        user.didUpdate(at: networkDate)
    }
    
}
